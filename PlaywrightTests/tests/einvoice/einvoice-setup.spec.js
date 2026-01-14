import { test, expect } from "@playwright/test";
import path from "path";
import { fileURLToPath } from "url";

import { BC_BASE_URL } from "../../utils/env.js";
import { getBCFrame } from "../../utils/bc/bc.frame.js";
import { openEFaturaSetupMenu, openMenuItem } from "../../utils/bc/bc.shell.js";
import { getGrid, resetGridToTop, findRowByContainsAll } from "../../utils/bc/bc.grid.js";
import { normalizeText } from "../../utils/bc/bc.text.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const storageStatePath = path.resolve(__dirname, "../../../storageState.json");

test.use({ storageState: storageStatePath });

test.beforeEach(async ({ page }) => {
  await page.goto(BC_BASE_URL, { waitUntil: "domcontentloaded" });
  // Debug için açabilirsin:
  // console.log("URL:", page.url());
  // await page.screenshot({ path: "after-goto.png", fullPage: true });
});
// ------------------------------
// 1) DURUM KODLARI
// ------------------------------
test("@smoke E-Fatura Durum Kodları sayfası validasyonlar", async ({ page }) => {
  test.setTimeout(5 * 60 * 1000);

  await page.goto(BC_BASE_URL, { waitUntil: "domcontentloaded" });
  const frame = await getBCFrame(page);


  await openEFaturaSetupMenu(frame);
  await openMenuItem(frame, /E-Fatura Durum Kodları/i);

  await expect(frame.locator('[id^="page-caption"]'))
    .toContainText(/E-Fatura Durum Kodları:/i);

  const expectedRows = [
    { code: "0",    description: "Taslak",               queueStatus: "Servise Gönderildi" },
    { code: "10",   description: "İptal Edildi",         queueStatus: "İptal Edildi" },
    { code: "100",  description: "Kuyrukta",             queueStatus: "Servise Gönderildi" },
    { code: "1000", description: "Onaylandı",            queueStatus: "Onaylandı" },
    { code: "1100", description: "Onay Bekliyor",        queueStatus: "Servise Gönderildi" },
    { code: "1200", description: "Reddedildi",           queueStatus: "Reddedildi" },
    { code: "1300", description: "İade Edildi",          queueStatus: "İptal Edildi" },
    { code: "1400", description: "E-Arşiv İptal Edildi", queueStatus: "İptal Edildi" },
    { code: "200",  description: "İşlemde",              queueStatus: "Servise Gönderildi" },
    { code: "2000", description: "Hata",                 queueStatus: "Başarısız" },
    { code: "300",  description: "Gib'e Gönderildi.",    queueStatus: "Servise Gönderildi" },
  ];

  const grid = await getGrid(frame);
  const errors = [];

  for (const exp of expectedRows) {
    await resetGridToTop({ page, grid });

    const row = await findRowByContainsAll({
      page,
      grid,
      mustContain: [exp.code, exp.description],
      maxScrolls: 25,
      waitMs: 60,
    });

    if (!row) {
      const shot = await page.screenshot({ fullPage: false }).catch(() => null);
      if (shot) {
        await test.info().attach(`missing-statuscode-${exp.code}.png`, {
          body: shot,
          contentType: "image/png",
        });
      }

      errors.push(
        [
          "❌ E-Fatura Durum Kodu Bulunamadı",
          `Code        : ${exp.code}`,
          `Description : ${exp.description}`,
          `QueueStatus : ${exp.queueStatus}`,
        ].join("\n")
      );
      continue;
    }

    const rowTextN = normalizeText(await row.innerText().catch(() => ""));
    expect.soft(rowTextN).toContain(normalizeText(exp.code));
    expect.soft(rowTextN).toContain(normalizeText(exp.description));
    expect.soft(rowTextN).toContain(normalizeText(exp.queueStatus));
  }

  if (errors.length) throw new Error(errors.join("\n\n"));
});

// ------------------------------
// 2) KOD EŞLEME
// ------------------------------
test("@smoke E-Fatura Kod Eşleme sayfası validasyonlar", async ({ page }) => {
  test.setTimeout(6 * 60 * 1000);

  await page.goto(BC_BASE_URL, { waitUntil: "domcontentloaded" });
  const frame = await getBCFrame(page);

  await openEFaturaSetupMenu(frame);
  await openMenuItem(frame, /E-Fatura Kod Eşleme/i);

  await expect(frame.locator('[id^="page-caption"]'))
    .toContainText(/E-Fatura Kod Eşleme/i);

  const expectedRows = [
    { type: "Ülke", source: "SA", destination: "SA", description: "SAUDI ARABIA" },
    { type: "Ülke", source: "UK", destination: "GB", description: "İngiltere" },

    { type: "UOM", source: "NIU",   destination: "NIU", description: "ADET" },
    { type: "UOM", source: "ADET",  destination: "NIU", description: "ADET" },
    { type: "UOM", source: "KASA",  destination: "NIU", description: "KASA" },
    { type: "UOM", source: "METRE", destination: "MTR", description: "METRE" },
    { type: "UOM", source: "PAKET", destination: "NIU", description: "PAKET" },

    { type: "EFat. Ödemek. Yöntem", source: "BANKA", destination: "42", description: "BANKA HAVALESİ" },
    { type: "EFat. Ödemek. Yöntem", source: "NAKIT", destination: "42", description: "NAKIT ÖDEME" },
    { type: "EFat. Ödemek. Yöntem", source: "PEŞİN", destination: "42", description: "PEŞİN" },

    { type: "EAR. İnternet Ödemesi. Yöntem", source: "BANKA",      destination: "EFT/HAVALE",            description: "EFT/HAVALE" },
    { type: "EAR. İnternet Ödemesi. Yöntem", source: "KREDİKARTI", destination: "KREDIKARTI/BANKAKARTI", description: "KREDİ KARTI" },
    { type: "EAR. İnternet Ödemesi. Yöntem", source: "NAKIT",      destination: "DIGER",                 description: "NAKIT ÖDEME" },
    { type: "EAR. İnternet Ödemesi. Yöntem", source: "PEŞİN",      destination: "42",                    description: "PEŞİN" },
  ];

  const grid = await getGrid(frame);
  const errors = [];

  for (const exp of expectedRows) {
    await resetGridToTop({ page, grid });

    const row = await findRowByContainsAll({
      page,
      grid,
      mustContain: [exp.type, exp.source],
      maxScrolls: 30,
      waitMs: 60,
    });

    if (!row) {
      const shot = await page.screenshot({ fullPage: false }).catch(() => null);
      if (shot) {
        await test.info().attach(`missing-mapping-${exp.type}-${exp.source}.png`, {
          body: shot,
          contentType: "image/png",
        });
      }

      errors.push(
        [
          "❌ Kod Eşleme Satırı Bulunamadı",
          `Type        : ${exp.type}`,
          `Source      : ${exp.source}`,
          `Destination : ${exp.destination}`,
          `Description : ${exp.description}`,
        ].join("\n")
      );
      continue;
    }

    const rowTextN = normalizeText(await row.innerText().catch(() => ""));
    expect.soft(rowTextN).toContain(normalizeText(exp.type));
    expect.soft(rowTextN).toContain(normalizeText(exp.source));
    expect.soft(rowTextN).toContain(normalizeText(exp.destination));
    expect.soft(rowTextN).toContain(normalizeText(exp.description));
  }

  if (errors.length) throw new Error(errors.join("\n\n"));
});

// ------------------------------
// 3) VERGİ TÜRÜ KODLARI
// ------------------------------
test("@smoke E-Fatura Vergi Türü Kodları sayfası validasyonlar", async ({ page }) => {
  test.setTimeout(8 * 60 * 1000);

  await page.goto(BC_BASE_URL, { waitUntil: "domcontentloaded" });
  const frame = await getBCFrame(page);

  await openEFaturaSetupMenu(frame);
  await openMenuItem(frame, /E-Fatura Vergi Türü Kodu/i);

  await expect(frame.locator('[id^="page-caption"]'))
    .toContainText(/E-Fatura Vergi Türü/i);

  const expectedRows = [
    { code: "0015", description: "uuu", type: "KDV",      calcOrder: "0", rate: "20,00" },
    { code: "8001", description: "KDV Tevkifatı", type: "Tevkifat", calcOrder: "0", rate: "70,00" },
    { code: "8002", description: "KDV Tevkifatı", type: "Tevkifat", calcOrder: "0", rate: "90,00" },
    { code: "825",  description: "Demir-Çelik Ürünlerinin Teslimi", type: "Tevkifat", calcOrder: "0", rate: "100,00" },

    { code: "9021", description: "4961 Banka Sigorta Muameleleri Vergisi", type: "KDV", calcOrder: "0", rate: "0,00" },
    { code: "9040", description: "Mera Fonu", type: "KDV", calcOrder: "0", rate: "0,00" },
    { code: "9077", description: "Motorlu Taşıt Araçlarına İlişkin Özel Tüketim Vergisi (Tescile Tabi Olanlar)", type: "KDV", calcOrder: "0", rate: "0,00" },
  ];

  const SEARCH_SCROLLS = 35;
  const SEARCH_WAIT_MS = 60;

  const grid = await getGrid(frame);
  const errors = [];

  for (const exp of expectedRows) {
    await resetGridToTop({ page, grid });

    const row = await findRowByContainsAll({
      page,
      grid,
      mustContain: [exp.code, exp.description],
      maxScrolls: SEARCH_SCROLLS,
      waitMs: SEARCH_WAIT_MS,
    });

    if (!row) {
      const shot = await page.screenshot({ fullPage: false }).catch(() => null);
      if (shot) {
        await test.info().attach(`missing-taxtype-${exp.code}.png`, {
          body: shot,
          contentType: "image/png",
        });
      }

      errors.push(
        [
          "❌ Vergi Türü Kodu satırı bulunamadı",
          `Code       : ${exp.code}`,
          `Desc       : ${exp.description}`,
          `Type       : ${exp.type}`,
          `CalcOrder  : ${exp.calcOrder}`,
          `Rate       : ${exp.rate}`,
        ].join("\n")
      );
      continue;
    }

    const rowTextN = normalizeText(await row.innerText().catch(() => ""));
    expect.soft(rowTextN).toContain(normalizeText(exp.code));
    expect.soft(rowTextN).toContain(normalizeText(exp.description));
    expect.soft(rowTextN).toContain(normalizeText(exp.type));
    expect.soft(rowTextN).toContain(normalizeText(exp.calcOrder));
    expect.soft(rowTextN).toContain(normalizeText(exp.rate));
  }

  if (errors.length) throw new Error(errors.join("\n\n"));
});
