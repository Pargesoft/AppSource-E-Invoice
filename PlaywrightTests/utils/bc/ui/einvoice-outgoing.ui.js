// PlaywrightTests/utils/bc/ui/einvoice-outgoing.ui.js
import { expect } from "@playwright/test";
import { getBcFrame, expectRoleCenterReady } from "./bc-frame.js";

/**
 * ✅ Deftere Naklet (Post) -> Evet -> "Fatura,DSF..." dialog -> Hayır
 * Codegen’e sadık:
 * - iframe[title="undefined"] içinden
 * - confirm dialog görünene kadar retry
 * - SENİN DEDİĞİN GİBİ: F9 en stabil yol
 */
// PlaywrightTests/utils/bc/ui/einvoice-outgoing.ui.js


export async function postInvoiceAndCloseDialogs(page) {
  const frame = await page.locator('iframe[title="undefined"]').contentFrame();
  if (!frame) throw new Error('BC iframe[title="undefined"] contentFrame alınamadı');

  // 1) Satış Faturası formunda olduğumuzu garanti et (yanlış ekranda F9/click işe yaramaz)
  const salesForm = frame.getByRole("form", { name: /Satış Faturası/i }).first();
  await expect(salesForm).toBeVisible({ timeout: 60000 });

  // 2) "Çıkmak istiyor musunuz?" diyaloğu (Geri tetiklenirse gelir)
  const leaveDlg = frame
    .getByRole("dialog", { name: /Belge kaydedildi|Çıkmak istediğinize emin misiniz/i })
    .first();
  const leaveHayir = frame.getByRole("button", { name: /^Hayır$/i }).first();

  // 3) Confirm / Posted dialoglar
  const confirmDlg = frame.getByRole("dialog", { name: /Do you want to post the|Deftere Naklet/i }).first();
  const postedDlg = frame.getByRole("dialog", { name: /Fatura,|Invoice,/i }).first();

  // 4) Deftere Naklet butonu (codegen'e en yakın: commandBarItemButton***)
  //    NOT: role ile değil, direkt id+aria-label ile.
  const postBtn = frame.locator('button[id^="commandBarItemButton"][aria-label="Deftere Naklet"]').first();
  await expect(postBtn).toBeVisible({ timeout: 60000 });

  // 5) Güvenli fokus: CLICK YOK. Sadece focus().
  //    (Bu, Geri'yi asla tetiklemez.)
  const safeFocus = async () => {
    const candidates = [
      frame.getByRole("textbox", { name: /Harici Belge No/i }).first(),
      frame.getByRole("combobox", { name: /Müşteri Adı/i }).first(),
      frame.getByRole("textbox", { name: /^No$/i }).first(),
    ];

    for (const c of candidates) {
      if (await c.isVisible().catch(() => false)) {
        await c.focus().catch(() => {});
        return;
      }
    }

    // Son çare: formun kendisine focus (click yok)
    await salesForm.focus().catch(() => {});
  };

  // 6) Eğer leave dialog zaten açıksa 1 kez kapat
  if (await leaveDlg.isVisible().catch(() => false)) {
    await leaveHayir.click({ force: true }).catch(() => {});
    await page.waitForTimeout(250);
  }

  // 7) Deneme döngüsü (DOM click + F9)
  let opened = false;
  let leaveSeenCount = 0;

  for (let i = 0; i < 10; i++) {
    // Edit mode vs. için ESC
    await page.keyboard.press("Escape").catch(() => {});
    await page.waitForTimeout(100);

    // ✅ click değil focus
    await safeFocus();
    await page.waitForTimeout(80);

    // A) Önce DOM click (pointer interception yok)
    try {
      await postBtn.evaluate((el) => el.click());
    } catch {}

    await page.waitForTimeout(500);

    // Eğer confirm geldiyse tamam
    if (await confirmDlg.isVisible().catch(() => false)) {
      opened = true;
      break;
    }

    // Eğer "çıkış" diyaloğu geldiyse: 1 kere kapat, 2. kez gelirse artık hata (geri tetikleniyor demektir)
    if (await leaveDlg.isVisible().catch(() => false)) {
      leaveSeenCount++;
      await leaveHayir.click({ force: true }).catch(() => {});
      await page.waitForTimeout(250);

      if (leaveSeenCount >= 2) {
        throw new Error(
          'Deftere Naklet tetiklenirken sistem "Geri/Çıkış" diyaloğunu tekrar tekrar açıyor. ' +
            "Bu yüzden tıklama/F9 komutu Deftere Naklet yerine Geri'yi tetikliyor."
        );
      }
    }

    // B) F9 (ana fallback)
    await safeFocus();
    await page.waitForTimeout(80);
    await page.keyboard.press("F9").catch(() => {});
    await page.waitForTimeout(700);

    if (await confirmDlg.isVisible().catch(() => false)) {
      opened = true;
      break;
    }

    // aynı kontrol: leave dialog tekrar gelirse
    if (await leaveDlg.isVisible().catch(() => false)) {
      leaveSeenCount++;
      await leaveHayir.click({ force: true }).catch(() => {});
      await page.waitForTimeout(250);

      if (leaveSeenCount >= 2) {
        throw new Error(
          'F9 sonrası sistem "Geri/Çıkış" diyaloğunu tekrar tekrar açıyor. ' +
            "Bu yüzden Deftere Naklet tetiklenemiyor."
        );
      }
    }
  }

  if (!opened) {
    throw new Error("Deftere Naklet tetiklenemedi (DOM click + F9 denendi) ve confirm dialog gelmedi");
  }

  // Confirm → Evet
  await frame.getByRole("button", { name: /^Evet$/i }).first().click({ force: true });

  // Posted dialog
  await expect(postedDlg).toBeVisible({ timeout: 60000 });

  // Hayır ile kapat
  await frame.getByRole("button", { name: /^Hayır$/i }).first().click({ force: true });
}


/**
 * TellMe (Ara) üzerinden menü açıp hedef sayfaya git
 */
async function openFromTellMe(page, frame, searchText, hitExactText, formNameRegex) {
  const araBtn = page.getByRole("button", { name: "Ara" }).first();
  await expect(araBtn).toBeVisible({ timeout: 60000 });
  await araBtn.click();

  // Codegen input label'i
  const searchInput = frame.getByRole("textbox", { name: /^Bana ne yapmak istediğinizi s/i }).first();
  const input = (await searchInput.isVisible().catch(() => false)) ? searchInput : frame.locator("input:visible").first();

  await expect(input).toBeVisible({ timeout: 60000 });
  await input.click();
  await input.fill(searchText);

  const hitRow = frame.getByRole("row", { name: new RegExp(hitExactText, "i") }).first();
  await expect(hitRow).toBeVisible({ timeout: 60000 });

  const hit = frame.getByText(hitExactText, { exact: true }).first();
  await expect(hit).toBeVisible({ timeout: 60000 });
  await hit.click();

  await expect(frame.getByRole("form", { name: formNameRegex }).first()).toBeVisible({ timeout: 60000 });
}
async function clickOkIfVisible(page, frame) {
  // Önce iframe içindeki görünür Tamam
  const okInFrame = frame.getByRole("button", { name: "Tamam", exact: true }).locator(":visible").first();
  if (await okInFrame.isVisible().catch(() => false)) {
    await okInFrame.click({ force: true });
    return true;
  }

  // Fallback: iframe dışındaki (page overlay) görünür Tamam
  const okOnPage = page.getByRole("button", { name: "Tamam", exact: true }).locator(":visible").first();
  if (await okOnPage.isVisible().catch(() => false)) {
    await okOnPage.click({ force: true });
    return true;
  }

  return false;
}
async function acceptInfoOk(page, frame, messagePart) {
  // 1) Mesaj iframe içinde mi?
  const dlgInFrame = frame.getByRole("dialog").filter({ hasText: messagePart }).first();
  if (await dlgInFrame.isVisible().catch(() => false)) {
    await dlgInFrame.getByRole("button", { name: "Tamam" }).click({ force: true });
    return true;
  }

  // 2) Mesaj page overlay’de mi?
  const dlgOnPage = page.getByRole("dialog").filter({ hasText: messagePart }).first();
  if (await dlgOnPage.isVisible().catch(() => false)) {
    await dlgOnPage.getByRole("button", { name: "Tamam" }).click({ force: true });
    return true;
  }

  // 3) Dialog değilse: sadece görünür "Tamam" fallback
  const okFrame = frame.getByRole("button", { name: "Tamam", exact: true }).locator(":visible").first();
  if (await okFrame.isVisible().catch(() => false)) {
    await okFrame.click({ force: true });
    return true;
  }

  const okPage = page.getByRole("button", { name: "Tamam", exact: true }).locator(":visible").first();
  if (await okPage.isVisible().catch(() => false)) {
    await okPage.click({ force: true });
    return true;
  }

  return false;
}
async function waitAndAcceptInfoOkFast(page, frame, messageRegex, { waitMs = 6000 } = {}) {
  const msgInFrame = frame.getByText(messageRegex).first();
  const msgOnPage = page.getByText(messageRegex).first();

  const winner = await Promise.race([
    msgInFrame.waitFor({ state: "visible", timeout: waitMs }).then(() => "frame").catch(() => null),
    msgOnPage.waitFor({ state: "visible", timeout: waitMs }).then(() => "page").catch(() => null),
  ]);

  if (!winner) {
    throw new Error(`Mesaj ${waitMs}ms içinde gelmedi: ${messageRegex}`);
  }

  // Mesajın geldiği tarafta (frame/page) dialog içinden Tamam’a bas
  const scope = winner === "frame" ? frame : page;

  const dlg = scope.getByRole("dialog").filter({ hasText: messageRegex }).first();
  if (await dlg.isVisible().catch(() => false)) {
    await dlg.getByRole("button", { name: "Tamam", exact: true }).click({ force: true });
    return;
  }

  // Dialog değilse: görünür Tamam’a bas
  await scope.getByRole("button", { name: "Tamam", exact: true }).locator(":visible").first().click({ force: true });
}




/**
 * ✅ E-Fatura Giden Faturalar sayfasına git
 * (Eğer zaten açıksa tekrar Ara’ya basma)
 */
export async function openOutgoingEInvoiceList(page) {
  const frame = await getBcFrame(page);
  await expectRoleCenterReady(frame, { timeoutMs: 60000 });

  const alreadyOpen = frame.getByRole("form", { name: /E-Fatura Giden Faturalar/i }).first();
  if (await alreadyOpen.isVisible().catch(() => false)) return frame;

  await openFromTellMe(page, frame, "giden efatura", "E-Fatura Giden Faturalar", /E-Fatura Giden Faturalar/i);
  return frame;
}

/**
 * ✅ "Gönderim" -> "E-fatura Oluştur"
 */
export async function createOutgoingEInvoiceQueue(page, { noFilter = "satışlar", postDateFilter = "b" } = {}) {
  const frame = await openOutgoingEInvoiceList(page);

  await frame.getByRole("menuitem", { name: "Gönderim" }).click();
  await expect(frame.getByRole("button", { name: "Sabitle" }).first()).toBeVisible({ timeout: 60000 });

  await frame.getByRole("menuitem", { name: "E-fatura Oluştur" }).click();
  await expect(frame.getByRole("dialog", { name: "E-Fatura Giden Kutusu Oluştur" }).first()).toBeVisible({ timeout: 60000 });

  await frame.getByRole("checkbox", { name: "G/M Kaydı Kullan" }).first().click();

  const noCombo = frame.getByRole("combobox", { name: "No" }).first();
  await noCombo.click();
  await noCombo.fill(noFilter);

  await expect(frame.getByRole("row", { name: /Hata Arandı No,/i }).first()).toBeVisible({ timeout: 60000 });
  await noCombo.press("Enter");

  await frame.getByRole("button", { name: "Alana yeni filtre ekle" }).first().click();
  await expect(frame.getByRole("listbox", { name: "Alana yeni filtre ekle" }).first()).toBeVisible({ timeout: 60000 });

  await frame.getByRole("option", { name: "Deftere Nakil Tarih" }).click();

  const postDate = frame.getByRole("textbox", { name: "Deftere Nakil Tarih", exact: true }).nth(1);
  await postDate.click();
  await postDate.fill(postDateFilter);
  await postDate.press("Enter");

  await frame.getByRole("button", { name: "Tamam" }).first().click();

  await expect(frame.getByRole("row", { name: /Giriş No\., Artan düzeninde/i }).first()).toBeVisible({ timeout: 60000 });
}

export async function sortOutgoingQueueByEntryNoDesc(page) {
  const frame = await getBcFrame(page);
  await expectRoleCenterReady(frame, { timeoutMs: 60000 });

  await frame.getByRole("button", { name: "Giriş No. için menüyü aç", exact: true }).first().click();
  await expect(frame.getByRole("menuitem", { name: "Artan" }).first()).toBeVisible({ timeout: 60000 });

  await frame.getByText("Azalan", { exact: true }).first().click();
  await expect(frame.getByRole("row", { name: /Giriş No\., Azalan düzeninde/i }).first()).toBeVisible({ timeout: 60000 });
}

export async function sendOutgoingEInvoice(page) {
  const frame = await getBcFrame(page);
  await expectRoleCenterReady(frame, { timeoutMs: 60000 });

  await frame.getByRole("menuitem", { name: "Gönderim" }).click();
  await expect(frame.getByRole("button", { name: "Sabitle" }).first()).toBeVisible({ timeout: 60000 });

  await frame.getByRole("menuitem", { name: "Gönder", exact: true }).click();

  await expect(frame.getByRole("row", { name: /Giriş No\., Azalan düzeninde/i }).first()).toBeVisible({ timeout: 60000 });
  await clickOkIfVisible(page, frame);

await waitAndAcceptInfoOkFast(page, frame, /Fatura entegratöre gönderildi/i, { waitMs: 6000 });

}

export async function queryOutgoingEInvoiceStatusAndExpectApproved(
  page,
  { expectedDocType = "E-Fatura" } = {}
) {
  let lastStatus = "";
  let lastDocType = "";

  for (let attempt = 1; attempt <= 3; attempt++) {
    const frame = await getBcFrame(page);
    await expectRoleCenterReady(frame, { timeoutMs: 60000 });

    const gonderim = frame.getByRole("menuitem", { name: "Gönderim" }).first();
    const sabitle = frame.getByRole("button", { name: "Sabitle" }).first();

    let menuOpened = false;
    for (let i = 0; i < 3; i++) {
      try {
        await gonderim.click({ force: true, timeout: 5000 });
      } catch {}

      if (await sabitle.isVisible().catch(() => false)) {
        menuOpened = true;
        break;
      }

      try {
        await gonderim.evaluate((el) => el.click());
      } catch {}

      if (await sabitle.isVisible().catch(() => false)) {
        menuOpened = true;
        break;
      }

      await page.waitForTimeout(200);
    }

    if (!menuOpened) {
      throw new Error('Gönderim menüsü açılamadı (Sabitle görünmedi).');
    }

    const durumBtn = frame.locator(
      `xpath=//*[starts-with(@id,'commandBarItemButton') and (
        contains(@aria-label,'Durum Sorgula') 
        or .//text()[contains(normalize-space(.),'Durum Sorgula')]
      )]`
    ).first();

    await expect(durumBtn).toBeVisible({ timeout: 60000 });
    await expect(durumBtn).toBeEnabled({ timeout: 60000 });

    await durumBtn.evaluate((el) => el.click());

    await page.waitForTimeout(10000);

    const statusCell = frame.locator(
      `xpath=//caption[text()='PRG_E-Invoice Outgoing Queue']/parent::table//tbody//tr[1]/td[6]`
    ).first();

    const docTypeCell = frame.locator(
      `xpath=//caption[text()='PRG_E-Invoice Outgoing Queue']/parent::table//tbody//tr[1]/td[5]`
    ).first();

    lastStatus = (await statusCell.innerText().catch(() => "")).trim();
    lastDocType = (await docTypeCell.innerText().catch(() => "")).trim();

    console.log(`Attempt ${attempt} status:`, lastStatus);
    console.log(`Attempt ${attempt} docType:`, lastDocType);

    if (
      lastStatus.includes("Onaylandı") &&
      lastDocType.includes(expectedDocType)
    ) {
      return;
    }

    if (attempt === 2) {
      console.log("⏳ 3. denemeden önce 2 dakika bekleniyor...");
      await page.waitForTimeout(120000);
    }
  }

  throw new Error(
    `Durum "Onaylandı" ve belge tipi "${expectedDocType}" olmadı. Son status: "${lastStatus}", Tip: "${lastDocType}"`
  );
}








