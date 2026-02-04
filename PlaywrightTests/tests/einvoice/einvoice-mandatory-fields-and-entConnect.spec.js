import { test, expect } from "@playwright/test";
import { BC_BASE_URL } from "../../utils/env.js";

/**
 * ✅ einvoice getBcFrame çözümü
 */
async function getBcFrame(page, { timeoutMs = 60000 } = {}) {
  const started = Date.now();

  while (Date.now() - started < timeoutMs) {
    const main = page.frame({ name: "MainContent" });
    if (main) return main;

    for (const f of page.frames()) {
      const url = f.url() || "";
      const isLikelyBc =
        /businesscentral\.dynamics\.com/i.test(url) || /\/Core/i.test(url) || /\/Sandbox/i.test(url);

      if (!isLikelyBc) continue;

      try {
        if ((await f.locator('[id^="page-caption"]').first().count()) > 0) return f;
      } catch {}

      try {
        if ((await f.locator('[role="grid"]').first().count()) > 0) return f;
      } catch {}

      try {
        if ((await f.getByRole("menuitem").first().count()) > 0) return f;
      } catch {}
    }

    await page.waitForTimeout(250);
  }

  const urls = page.frames().map((f) => f.url()).filter(Boolean);
  throw new Error(`BC main frame bulunamadı (${timeoutMs}ms). Bulunan frame URL'leri:\n- ${urls.join("\n- ")}`);
}

/**
 * ✅ einvoice openMenu frame çözümü
 */
async function openMenu(frame) {
  await expect(frame.getByRole("menuitem").first()).toBeVisible({ timeout: 60000 });

  const efaturaMenu = frame.getByRole("menuitem", { name: /Pargesoft E-Fatura/i });
  await expect(efaturaMenu).toBeVisible({ timeout: 60000 });
  await efaturaMenu.click();

  await expect(frame.getByRole("button", { name: /Sabitle/i })).toBeVisible({ timeout: 30000 });

  const kurulum = frame.getByRole("menuitem", { name: /^Kurulum$/i });
  await expect(kurulum).toBeVisible({ timeout: 30000 });
  await kurulum.click();

  await expect(frame.getByRole("menu", { name: /^Kurulum$/i })).toBeVisible({ timeout: 30000 });
}

/**
 * ✅ E-Fatura Kurulumu sayfasına git
 * (sayfa açıldığını textbox’larla doğruluyoruz)
 */
async function openEFaturaKurulumu(page) {
  const frame = await getBcFrame(page);

  await openMenu(frame);

  await frame.getByRole("menuitem", { name: /E-Fatura Kurulumu/i }).click();

  await expect(frame.getByRole("textbox", { name: /E-Fatura Başlangıç Tarihi/i })).toBeVisible({
    timeout: 60000,
  });

  await expect(frame.getByRole("textbox", { name: /E-Arşiv Başlangıç Tarihi/i })).toBeVisible({
    timeout: 60000,
  });

  return frame;
}

/**
 * ✅ Textbox alanı dolu mu?
 * BC’de textbox bazen <input>, bazen <span role="textbox" aria-readonly="true"> olur.
 */
async function expectTextboxHasValue(frame, labelRegex) {
  const field = frame.getByRole("textbox", { name: labelRegex });
  await expect(field).toBeVisible({ timeout: 60000 });

  const value = (await field.inputValue().catch(() => "")) || (await field.textContent().catch(() => "")) || "";
  expect(value.trim(), `Alan boş: ${labelRegex}`).not.toBe("");
}

/**
 * ✅ Lookup alanlarında (caption + value) strict mode çözümü
 * captionRegex örn: /Fatura No\. Serisi/i
 */
async function expectLookupHasValue(frame, captionRegex) {
  const buttons = frame.getByRole("button", { name: captionRegex });

  await expect(buttons.first()).toBeVisible({ timeout: 60000 });

  const count = await buttons.count();
  const captionBtn = buttons.first();
  const valueBtn = count >= 2 ? buttons.nth(1) : buttons.first();

  await expect(valueBtn).toBeVisible({ timeout: 60000 });

  const captionText = ((await captionBtn.textContent().catch(() => "")) || "").trim();
  const valueText = ((await valueBtn.textContent().catch(() => "")) || "").trim();

  expect(valueText, `Lookup değeri boş: ${captionRegex}`).not.toBe("");

  if (captionText) {
    expect(
      valueText.toLowerCase(),
      `Lookup value bulunamadı (value caption ile aynı): caption="${captionText}" value="${valueText}"`
    ).not.toBe(captionText.toLowerCase());
  }
}

test.describe("@smoke @regression E-Fatura Kurulumu", () => {
  test("Mandatory fields populated (configuration validation)", async ({ page }) => {
    test.setTimeout(6 * 60 * 1000);

    await page.goto(BC_BASE_URL, { waitUntil: "domcontentloaded" });
    await page.waitForURL(/businesscentral\.dynamics\.com/i, { timeout: 60000 });

    const frame = await test.step("Navigate to E-Fatura Kurulumu", async () => {
      return await openEFaturaKurulumu(page);
    });

    await test.step("Check: E-Fatura Başlangıç Tarihi dolu", async () => {
      await expectTextboxHasValue(frame, /E-Fatura Başlangıç Tarihi/i);
    });

    await test.step("Check: E-Arşiv Başlangıç Tarihi dolu", async () => {
      await expectTextboxHasValue(frame, /E-Arşiv Başlangıç Tarihi/i);
    });

    await test.step("Check: Fatura No. Serisi seçili", async () => {
      await expectLookupHasValue(frame, /Fatura No\. Serisi/i);
    });

    await test.step("Check: LPB Kuruş Belirteci dolu", async () => {
      await expectTextboxHasValue(frame, /LPB Kuruş Belirteci/i);
    });

    await test.step("Check: Şirket Vergi Kimlik No. dolu", async () => {
      await expectTextboxHasValue(frame, /Şirket Vergi Kimlik No\./i);
    });

    await test.step("Check: Tedarikçi Kaydı No Türü dolu", async () => {
      await expectTextboxHasValue(frame, /Tedarikçi Kaydı No. Türü/i);
    });

    await test.step("Check: Şirket Ticaret Sicil No. dolu", async () => {
      await expectTextboxHasValue(frame, /Şirket Ticaret Sicil No\./i);
    });

    await test.step("Check: Şirket Adı dolu", async () => {
      await expectTextboxHasValue(frame, /Şirket Adı/i);
    });

    await test.step("Check: Şirket Vergi Dairesi dolu", async () => {
      await expectTextboxHasValue(frame, /Şirket Vergi Dairesi/i);
    });

    await test.step("Check: Şirket Ülkesi dolu", async () => {
      await expectTextboxHasValue(frame, /Şirket Ülkesi/i);
    });

    await test.step("Check: Şirket Şehri dolu", async () => {
      await expectTextboxHasValue(frame, /Şirket Şehri/i);
    });

    await test.step("Check: Şirket İlçesi dolu", async () => {
      await expectTextboxHasValue(frame, /Şirket İlçesi/i);
    });

    await test.step("Check: Şirket Adresi dolu", async () => {
      await expectTextboxHasValue(frame, /Şirket Adresi/i);
    });

    await test.step("Check: Şirket Telefonu dolu", async () => {
      await expectTextboxHasValue(frame, /Şirket Telefonu/i);
    });

    await test.step("Check: Şirket E-Posta dolu", async () => {
      await expectTextboxHasValue(frame, /Şirket E-Posta/i);
    });

    await test.step("Check: Şirket Mersis No dolu", async () => {
      await expectTextboxHasValue(frame, /Şirket Mersis No/i);
    });

    await test.step("Click: Varsayılan", async () => {
      await frame.getByRole("button", { name: /^Varsayılan$/i }).click();
    });

    await test.step("Check: KDV Vergi Türü Kodu seçili", async () => {
      await expectLookupHasValue(frame, /KDV Vergi Türü Kodu/i);
    });
  });

  // ✅ AYRI TEST: Entegratör bağlantı testi
  test("E-Fatura Entegratör bağlantısı başarılı", async ({ page }) => {
    test.setTimeout(3 * 60 * 1000);

    await page.goto(BC_BASE_URL, { waitUntil: "domcontentloaded" });
    await page.waitForURL(/businesscentral\.dynamics\.com/i, { timeout: 60000 });

    await testEFaturaIntegratorConnection(page);
  });
});

/**
 * ✅ Fonksiyon en altta: E-Fatura Entegratör Kurulumu -> Bağlantıyı Test Et
 */
async function testEFaturaIntegratorConnection(page) {
  const frame = await getBcFrame(page);

  // Menü: Pargesoft E-Fatura -> Kurulum
  await openMenu(frame);

  // E-Fatura Entegratör Kurulumu
  await frame.getByRole("menuitem", { name: /E-Fatura Entegratör Kurulumu/i }).click();

  await expect(frame.getByRole("form", { name: /Pargesoft E-Fatura/i }).first()).toBeVisible({ timeout: 60000 });

  // Bağlantıyı Test Et
  await frame.getByRole("menuitem", { name: /Bağlantıyı Test Et/i }).click();

  // Başarı mesajı
  await expect(frame.getByText(/Bağlantı testi başarılı!/i).first()).toBeVisible({ timeout: 60000 });
}
