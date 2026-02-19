// PlaywrightTests/tests/einvoice/einvoice-setup.spec.js
import { test, expect } from '@playwright/test';
import { BC_BASE_URL } from '../../utils/env.js';
import XLSX from 'xlsx';

import path from 'path';

const norm = (s) =>
  (s || '')
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
    .toLowerCase();

/**
 * ✅ BC main content frame’i güvenli şekilde bulur.
 * - Önce name=MainContent
 * - Sonra frame url + UI işaretleri (menuitem/caption/grid)
 * - Bekleyerek tarar (iframe geç yüklenebiliyor)
 */
async function getBcFrame(page, { timeoutMs = 60000 } = {}) {
  const started = Date.now();

  while (Date.now() - started < timeoutMs) {
    // 1) En güvenilir: MainContent
    const main = page.frame({ name: 'MainContent' });
    if (main) return main;

    // 2) Frame’leri tara
    for (const f of page.frames()) {
      const url = f.url() || '';

      const isLikelyBc =
        /businesscentral\.dynamics\.com/i.test(url) ||
        /\/Core/i.test(url) ||
        /\/Sandbox/i.test(url);

      if (!isLikelyBc) continue;

      try {
        if ((await f.locator('[id^="page-caption"]').first().count()) > 0) return f;
      } catch {}

      try {
        if ((await f.locator('[role="grid"]').first().count()) > 0) return f;
      } catch {}

      // Menü varsa kesin BC UI içindeyiz
      try {
        if ((await f.getByRole('menuitem').first().count()) > 0) return f;
      } catch {}
    }

    // 3) iframe geç gelebilir → kısa bekle
    await page.waitForTimeout(250);
  }

  const urls = page.frames().map((f) => f.url()).filter(Boolean);
  throw new Error(
    `BC main frame bulunamadı (${timeoutMs}ms). Bulunan frame URL'leri:\n- ${urls.join('\n- ')}`
  );
}

async function openMenu(frame) {
  // ✅ Role Center adı değişebilir; form adına bağlanma.
  // Menü item'ler render olana kadar bekle.
  await expect(frame.getByRole('menuitem').first()).toBeVisible({ timeout: 60000 });

  const efaturaMenu = frame.getByRole('menuitem', { name: /Pargesoft E-Fatura/i });
  await expect(efaturaMenu).toBeVisible({ timeout: 60000 });
  await efaturaMenu.click();

  await expect(frame.getByRole('button', { name: /Sabitle/i }))
    .toBeVisible({ timeout: 30000 });

  const kurulum = frame.getByRole('menuitem', { name: /^Kurulum$/i });
  await expect(kurulum).toBeVisible({ timeout: 30000 });
  await kurulum.click();

  await expect(frame.getByRole('menu', { name: /^Kurulum$/i }))
    .toBeVisible({ timeout: 30000 });
}

async function getGrid(frame) {
  const grid = frame.locator('[role="grid"]:has([role="gridcell"])').first();
  await expect(grid).toBeVisible({ timeout: 30000 });
  await grid.click().catch(() => {});
  return grid;
}

// ✅ Grid’i en üste al (her aramada baştan başlasın, süre düşer)
async function resetGridToTop({ page, grid }) {
  await grid.click().catch(() => {});
  await page.keyboard.press('Home').catch(() => {});
  await page.waitForTimeout(80);
}

async function findRowByContainsAll({
  page,
  grid,
  mustContain = [],
  maxScrolls = 40,
  waitMs = 80,
}) {
  const must = mustContain.map(norm);

  for (let i = 0; i < maxScrolls; i++) {
    const rows = grid.getByRole('row');
    const count = await rows.count();

    for (let r = 0; r < count; r++) {
      const row = rows.nth(r);
      const txtN = norm(await row.innerText().catch(() => ''));
      if (!txtN) continue;

      const ok = must.every((m) => txtN.includes(m));
      if (ok) return row;
    }

    await page.keyboard.press('PageDown');
    await page.waitForTimeout(waitMs);
  }

  return null;
}
async function collectAllGridRowsTextFast({
  page,
  grid,
  maxScrolls = 220,
  waitMs = 25,
  stableRoundsToStop = 4, // yeni satır gelmiyorsa erken bitir
}) {
  const seen = new Set();

  // Focus + start from top
  await grid.click().catch(() => {});
  await page.keyboard.press('Home').catch(() => {});
  await page.waitForTimeout(120);

  let stable = 0;

  for (let i = 0; i < maxScrolls; i++) {
    const before = seen.size;

    // ✅ Tek seferde tüm görünen row textlerini al (çok hızlı)
    const texts = await grid.getByRole('row').evaluateAll((rows) =>
      rows
        .map((r) => (r.innerText || '').replace(/\s+/g, ' ').trim())
        .filter(Boolean)
    );

    for (const t of texts) seen.add(t);

    // ✅ yeni satır gelmiyorsa say
    if (seen.size === before) stable++;
    else stable = 0;

    // ✅ 4 tur üst üste yeni satır yoksa grid sonu gelmiştir → çık
    if (stable >= stableRoundsToStop) break;

    await page.keyboard.press('PageDown').catch(() => {});
    await page.waitForTimeout(waitMs);
  }

  // normalize edip dön
  return [...seen].map(norm);
}


function rowHasAllParts(rowTextNorm, parts = []) {
  const must = parts.map(norm);
  return must.every((m) => rowTextNorm.includes(m));
}
function loadTaxTypeRowsFromExcel(excelPath) {
  const wb = XLSX.readFile(excelPath);
  const sheetName = wb.SheetNames[0];
  const ws = wb.Sheets[sheetName];

  // header'ları anahtar yaparak oku
  const raw = XLSX.utils.sheet_to_json(ws, { defval: '' });

  // Excel başlıkları sende şöyleydi:
  // KodArtan | Açıklama | Tür | Hesaplama Sıra Numarası | Vergi Oranı
  const rows = raw
    .map((r) => ({
      code: String(r['KodArtan'] ?? r['Kod'] ?? r['Code'] ?? '').trim(),
      description: String(r['Açıklama'] ?? r['Aciklama'] ?? r['Description'] ?? '').trim(),
      type: String(r['Tür'] ?? r['Tur'] ?? r['Type'] ?? '').trim(),
      calcOrder: String(r['Hesaplama Sıra Numarası'] ?? r['Hesaplama Sira Numarasi'] ?? r['CalcOrder'] ?? '').trim(),
      rate: String(r['Vergi Oranı'] ?? r['Vergi Orani'] ?? r['Rate'] ?? '').trim(),
    }))
    // boş satırları at
    .filter((x) => x.code || x.description);

  if (!rows.length) {
    throw new Error(`Excel boş ya da kolon adları eşleşmedi: ${excelPath}`);
  }

  return rows;
}



// ------------------------------
// 1) DURUM KODLARI
// ------------------------------
test('@smoke E-Fatura Durum Kodları sayfası validasyonlar', async ({ page }) => {
  test.setTimeout(5 * 60 * 1000);

  // ✅ BC için networkidle yerine domcontentloaded
  await page.goto(BC_BASE_URL, { waitUntil: 'domcontentloaded' });
  await page.waitForURL(/businesscentral\.dynamics\.com/i, { timeout: 60000 });

  const frame = await getBcFrame(page);

  await openMenu(frame);
  await frame.getByRole('menuitem', { name: /E-Fatura Durum Kodları/i }).click();

  await expect(frame.locator('[id^="page-caption"]'))
    .toContainText(/E-Fatura Durum Kodları:/i);

const expectedRows = [
  { code: '0',    description: 'Taslak',                         queueStatus: 'Servise Gönderildi' },
  { code: '10',   description: 'İptal Edildi',                   queueStatus: 'İptal Edildi' },
  { code: '100',  description: 'Kuyrukta',                       queueStatus: 'Servise Gönderildi' },
  { code: '1000', description: 'Onaylandı',                      queueStatus: 'Onaylandı' },
  { code: '1100', description: 'Onay Bekliyor',                  queueStatus: 'Servise Gönderildi' },
  { code: '1200', description: 'Reddedildi',                     queueStatus: 'Reddedildi' },
  { code: '1300', description: 'İade Edildi',                    queueStatus: 'İptal Edildi' },
  { code: '1400', description: 'E-Arşiv İptal Edildi',           queueStatus: 'İptal Edildi' },
  { code: '200',  description: 'İşlemde',                        queueStatus: 'Servise Gönderildi' },
  { code: '2000', description: 'XML Şema Kontrolünden Geçemedi', queueStatus: 'Başarısız' },
  { code: '300',  description: "Gib'e Gönderildi.",              queueStatus: 'Servise Gönderildi' },
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
          contentType: 'image/png',
        });
      }

      errors.push(
        [
          '❌ E-Fatura Durum Kodu Bulunamadı',
          `Code        : ${exp.code}`,
          `Description : ${exp.description}`,
          `QueueStatus : ${exp.queueStatus}`,
        ].join('\n')
      );
      continue;
    }

    const rowTextN = norm(await row.innerText().catch(() => ''));
    expect.soft(rowTextN).toContain(norm(exp.code));
    expect.soft(rowTextN).toContain(norm(exp.description));
    expect.soft(rowTextN).toContain(norm(exp.queueStatus));
  }

  if (errors.length) throw new Error(errors.join('\n\n'));
});

// ------------------------------
// 2) KOD EŞLEME
// ------------------------------
test('@smoke E-Fatura Kod Eşleme sayfası validasyonlar', async ({ page }) => {
  test.setTimeout(6 * 60 * 1000);

  await page.goto(BC_BASE_URL, { waitUntil: 'domcontentloaded' });
  await page.waitForURL(/businesscentral\.dynamics\.com/i, { timeout: 60000 });

  const frame = await getBcFrame(page);

  await openMenu(frame);
  await frame.getByRole('menuitem', { name: /E-Fatura Kod Eşleme/i }).click();

  await expect(frame.locator('[id^="page-caption"]'))
    .toContainText(/E-Fatura Kod Eşleme:/i);

  const expectedRows = [
  { type: 'Para Birimi', source: '', destination: 'TRY', description: 'TRY' },
  { type: 'Para Birimi', source: 'EUR', destination: 'EUR', description: 'EUR FOREX ALIŞ' },
  { type: 'Para Birimi', source: 'GBP', destination: 'GBP', description: 'GBP FOREX ALIŞ' },
  { type: 'Para Birimi', source: 'USD', destination: 'USD', description: 'USD FOREX ALIŞ' },

  { type: 'Ülke', source: 'TR', destination: 'TR', description: 'TÜRKİYE CUMHURİYETİ' },
  { type: 'Ülke', source: 'CA', destination: 'CA', description: 'CANADA' },
  { type: 'Ülke', source: 'DE', destination: 'DE', description: 'GERMANY' },
  { type: 'Ülke', source: 'ES', destination: 'ES', description: 'SPAIN' },
  { type: 'Ülke', source: 'IT', destination: 'IT', description: 'IT' },
  { type: 'Ülke', source: 'MV', destination: 'MV', description: 'MALDIVES' },
  { type: 'Ülke', source: 'NL', destination: 'NL', description: 'NETHERLANDS' },
  { type: 'Ülke', source: 'QA', destination: 'QA', description: 'QATAR' },
  { type: 'Ülke', source: 'RO', destination: 'RO', description: 'ROMANIA' },
  { type: 'Ülke', source: 'SA', destination: 'SA', description: 'SAUDI ARABİA' },
  { type: 'Ülke', source: 'TR', destination: 'TR', description: 'TÜRKİYE CUMHURİYETİ' },
  { type: 'Ülke', source: 'UK', destination: 'GB', description: 'İngiltere' },

  { type: 'UOM', source: 'NIU', destination: 'NIU', description: 'ADET' },
  { type: 'UOM', source: 'ADET', destination: 'NIU', description: 'ADET' },
  { type: 'UOM', source: 'KASA', destination: 'NIU', description: 'KASA' },
  { type: 'UOM', source: 'KG', destination: 'KGM', description: '' },
  { type: 'UOM', source: 'METRE', destination: 'MTR', description: 'METRE' },
  { type: 'UOM', source: 'PAKET', destination: 'NIU', description: 'PAKET' },

  { type: 'EFat. Ödemek. Yöntem', source: 'BANKA', destination: '42', description: 'BANKA HAVALESİ' },
  { type: 'EFat. Ödemek. Yöntem', source: 'NAKIT', destination: '42', description: 'NAKIT ÖDEME' },
  { type: 'EFat. Ödemek. Yöntem', source: 'PEŞİN', destination: '42', description: 'PEŞİN' },

  { type: 'EAR. İnternet Ödemesi. Yöntem', source: 'BANKA', destination: 'EFT/HAVALE', description: 'EFT/HAVALE' },
  { type: 'EAR. İnternet Ödemesi. Yöntem', source: 'KREDİKARTI', destination: 'KREDIKARTI/BANKAKARTI', description: 'KREDİ KARTI' },
  { type: 'EAR. İnternet Ödemesi. Yöntem', source: 'NAKIT', destination: 'DIGER', description: 'NAKIT ÖDEME' },
  { type: 'EAR. İnternet Ödemesi. Yöntem', source: 'PEŞİN', destination: '42', description: 'PEŞİN' },
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
          contentType: 'image/png',
        });
      }

      errors.push(
        [
          '❌ Kod Eşleme Satırı Bulunamadı',
          `Type        : ${exp.type}`,
          `Source      : ${exp.source}`,
          `Destination : ${exp.destination}`,
          `Description : ${exp.description}`,
        ].join('\n')
      );
      continue;
    }

    const rowTextN = norm(await row.innerText().catch(() => ''));
    expect.soft(rowTextN).toContain(norm(exp.type));
    expect.soft(rowTextN).toContain(norm(exp.source));
    expect.soft(rowTextN).toContain(norm(exp.destination));
    expect.soft(rowTextN).toContain(norm(exp.description));
  }

  if (errors.length) throw new Error(errors.join('\n\n'));
});

// ------------------------------
// 3) VERGİ TÜRÜ KODLARI
// ------------------------------
test('@smoke E-Fatura Vergi Türü Kodları sayfası validasyonlar', async ({ page }) => {
  test.setTimeout(12 * 60 * 1000);

  await page.goto(BC_BASE_URL, { waitUntil: 'domcontentloaded' });
  await page.waitForURL(/businesscentral\.dynamics\.com/i, { timeout: 60000 });
  const frame = await getBcFrame(page);

  await openMenu(frame);

  await frame.getByRole('menuitem', { name: /E-Fatura Vergi Türü Kodu/i }).click();

  await expect(frame.locator('[id^="page-caption"]').first())
    .toContainText(/E-Fatura Vergi Türü/i, { timeout: 60000 });

  console.log('XLSX keys sample:', Object.keys(XLSX).slice(0, 20));
  console.log('readFile type:', typeof XLSX.readFile);

  // ✅ Excel’den oku
  const excelPath = path.resolve(
    process.cwd(),
    'tests',
    'test-data',
    'E-Fatura Vergi Türü Kodu (1).xlsx'
  );

  const expectedRows = loadTaxTypeRowsFromExcel(excelPath);

  const grid = await getGrid(frame);

  // ✅ Grid'i 1 kere tara, bellekte kontrol et
  const allRows = await collectAllGridRowsTextFast({
    page,
    grid,
    maxScrolls: 220, // 178 satır için güvenli
    waitMs: 25,
    stableRoundsToStop: 4,
  });

  const errors = [];

  for (const exp of expectedRows) {
    // ✅ daha sağlam eşleşme: code + desc + rate
    const candidate = allRows.find((t) =>
      rowHasAllParts(t, [exp.code, exp.description, exp.rate])
    );

    if (!candidate) {
      const shot = await page.screenshot({ fullPage: false }).catch(() => null);
      if (shot) {
        await test.info().attach(`missing-taxtype-${exp.code}.png`, {
          body: shot,
          contentType: 'image/png',
        });
      }

      errors.push(
        [
          '❌ Vergi Türü Kodu satırı bulunamadı',
          `Code       : ${exp.code}`,
          `Desc       : ${exp.description}`,
          `Type       : ${exp.type}`,
          `CalcOrder  : ${exp.calcOrder}`,
          `Rate       : ${exp.rate}`,
        ].join('\n')
      );
      continue;
    }

    // Soft assert: satır içinde diğer alanlar da var mı?
    expect.soft(candidate).toContain(norm(exp.type));
    expect.soft(candidate).toContain(norm(exp.calcOrder));
    expect.soft(candidate).toContain(norm(exp.rate));
  }

  if (errors.length) throw new Error(errors.join('\n\n'));
});
// ------------------------------
// 4) XMLPORT - KULLANICILARI GÜNCELLE
// ------------------------------
test('@smoke E-Fatura Sorumlusu Şirketler > Kullancıları Güncelle XMLPort menüsüne git', async ({ page }) => {
  test.setTimeout(5 * 60 * 1000);

  await page.goto(BC_BASE_URL, { waitUntil: 'domcontentloaded' });
  await page.waitForURL(/businesscentral\.dynamics\.com/i, { timeout: 60000 });

  const frame = await getBcFrame(page);

  // Menü aç
  await openMenu(frame);

  // İlgili sayfaya git
  await frame.getByRole('menuitem', { name: /E-Fatura Sorumlusu Şirketler/i }).click();

  // Sayfa açıldı mı?
  await expect(frame.locator('[id^="page-caption"]').first()).toBeVisible({ timeout: 60000 });

  // "Gerisini göster" varsa aç
  const showMore = frame.getByRole('menuitem', { name: /Gerisini göster/i }).first();
  if ((await showMore.count()) > 0) {
    await showMore.click();
    await expect(frame.getByRole('menu', { name: /Gerisini göster/i })).toBeVisible({ timeout: 30000 });
  }

  // "Daha fazla seçenek" aç
  const moreOptions = frame.getByRole('menuitem', { name: /Daha fazla seçenek/i }).first();
  await expect(moreOptions).toBeVisible({ timeout: 30000 });
  await moreOptions.click();

  // ✅ 1) "Eylemler" görünür olmalı ve tıklanmalı (frame veya page overlay olabilir)
  const actionsFrame = frame.getByRole('menuitem', { name: /^Eylemler$/i }).first();
  const actionsPage = page.getByRole('menuitem', { name: /^Eylemler$/i }).first();

  if ((await actionsFrame.count()) > 0) {
    await expect(actionsFrame).toBeVisible({ timeout: 30000 });
    await actionsFrame.click();
  } else {
    await expect(actionsPage).toBeVisible({ timeout: 30000 });
    await actionsPage.click();
  }

  // ✅ 2) "Geçiş" menüsüne gir (frame veya page overlay olabilir)
  const navigateFrame = frame.getByRole('menuitem', { name: /Geçiş/i }).first();
  const navigatePage = page.getByRole('menuitem', { name: /Geçiş/i }).first();

  if ((await navigateFrame.count()) > 0) {
    await expect(navigateFrame).toBeVisible({ timeout: 30000 });
    await navigateFrame.click();
  } else {
    await expect(navigatePage).toBeVisible({ timeout: 30000 });
    await navigatePage.click();
  }

  // ✅ 3) XMLPort aksiyonunu seç (frame veya page overlay olabilir)
  const xmlportFrame = frame.getByRole('menuitem', { name: /Kullancıları Güncelle XMLPort/i }).first();
  const xmlportPage = page.getByRole('menuitem', { name: /Kullancıları Güncelle XMLPort/i }).first();

  if ((await xmlportFrame.count()) > 0) {
    await expect(xmlportFrame).toBeVisible({ timeout: 30000 });
    await xmlportFrame.click();
  } else {
    await expect(xmlportPage).toBeVisible({ timeout: 30000 });
    await xmlportPage.click();
  }

  //Assert: XMLPort sonrası bir dialog/request page/caption görünmeli
  await expect(frame.locator('[role="dialog"], [id^="page-caption"]').first()).toBeVisible({ timeout: 60000 });

  await page.waitForTimeout(120_000);

  // PRG_E-Invoice Liable Companies grid → first 6 rows, column 6 must be non-empty
const liableGrid = frame
  .getByRole('grid')
  .filter({ hasText: 'PRG_E-Invoice Liable Companies' })
  .first();

await expect(liableGrid).toBeVisible({ timeout: 60000 });

const rows = liableGrid.getByRole('row');
const rowCount = await rows.count();

// 0 = header, so we need at least 1 data row
expect(rowCount, 'Grid has no data rows').toBeGreaterThan(1);

const maxRowsToCheck = Math.min(6, rowCount - 1); // first 6 data rows
const emptyCells = [];

for (let i = 1; i <= maxRowsToCheck; i++) {
  const row = rows.nth(i); // 1..6 data rows (0 is header)
  const cell = row.getByRole('gridcell').nth(5); // column 6 -> index 5

  await expect(cell).toBeVisible({ timeout: 15000 });

  const value = (await cell.innerText().catch(() => '')).trim();
  if (!value) emptyCells.push(`Row ${i} col 6 is EMPTY`);
}

if (emptyCells.length) {
  throw new Error(
    ['❌ PRG_E-Invoice Liable Companies: column 6 has empty cells:', ...emptyCells].join('\n')
  );
}



});
