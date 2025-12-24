// PlaywrightTests/tests/einvoice/einvoice-setup.spec.js
import { test, expect } from '@playwright/test';
import { BC_BASE_URL } from '../../utils/env.js';

/**
 * ✅ Unicode-safe normalize
 * - Türkçe İ / i̇ problemi çözer
 */
const norm = (s) =>
  (s || '')
    .normalize('NFKD')                 // birleşik karakterleri ayır
    .replace(/[\u0300-\u036f]/g, '')   // combining marks temizle (i̇ gibi)
    .replace(/\s+/g, ' ')
    .trim()
    .toLowerCase();

async function openMenu(frame) {
  await expect(frame.getByRole('form', { name: /Business Manager/i }))
    .toBeVisible({ timeout: 60000 });

  await frame.getByRole('menuitem', { name: /Pargesoft E-Fatura/i }).click();

  // Sabitle görünüyorsa menü açıldı
  await expect(frame.getByRole('button', { name: /Sabitle/i }))
    .toBeVisible({ timeout: 30000 });

  await frame.getByRole('menuitem', { name: /^Kurulum$/i }).click();
  await expect(frame.getByRole('menu', { name: /^Kurulum$/i }))
    .toBeVisible({ timeout: 30000 });
}

async function getGrid(frame) {
  const grid = frame.locator('[role="grid"]:has([role="gridcell"])').first();
  await expect(grid).toBeVisible({ timeout: 30000 });
  await grid.click().catch(() => {});
  return grid;
}

test('@smoke E-Fatura Durum Kodları sayfası validasyonlar', async ({ page }) => {
  test.setTimeout(5 * 60 * 1000);

  await page.goto(BC_BASE_URL, { waitUntil: 'networkidle' });
  const frame = page.frameLocator('iframe[title="undefined"]');

  await openMenu(frame);

  await frame.getByRole('menuitem', { name: /E-Fatura Durum Kodları/i }).click();

  // ✅  caption check
  await expect(frame.locator('[id^="page-caption"]'))
    .toContainText(/E-Fatura Durum Kodları:/i);

  const expectedRows = [
    { code: '0',    description: 'Taslak',               queueStatus: 'Servise Gönderildi' },
    { code: '10',   description: 'İptal Edildi',         queueStatus: 'İptal Edildi' },
    { code: '100',  description: 'Kuyrukta',             queueStatus: 'Servise Gönderildi' },
    { code: '1000', description: 'Onaylandı',            queueStatus: 'Onaylandı' },
    { code: '1100', description: 'Onay Bekliyor',        queueStatus: 'Servise Gönderildi' },
    { code: '1200', description: 'Reddedildi',           queueStatus: 'Reddedildi' },
    { code: '1300', description: 'İade Edildi',          queueStatus: 'İptal Edildi' },
    { code: '1400', description: 'E-Arşiv İptal Edildi', queueStatus: 'İptal Edildi' },
    { code: '200',  description: 'İşlemde',              queueStatus: 'Servise Gönderildi' },
    { code: '2000', description: 'Hata',                 queueStatus: 'Başarısız' },
    { code: '300',  description: "Gib'e Gönderildi.",    queueStatus: 'Servise Gönderildi' },
  ];

  const grid = await getGrid(frame);

  async function findRowByCodeAndDesc(code, description, maxScrolls = 60) {
    const codeN = norm(code);
    const descN = norm(description);

    for (let i = 0; i < maxScrolls; i++) {
      const rows = grid.getByRole('row');
      const count = await rows.count();

      for (let r = 0; r < count; r++) {
        const row = rows.nth(r);
        const txtN = norm(await row.innerText().catch(() => ''));
        if (!txtN) continue;
        if (txtN.includes(codeN) && txtN.includes(descN)) return row;
      }

      await page.keyboard.press('PageDown');
      await page.waitForTimeout(150);
    }
    return null;
  }

  for (const exp of expectedRows) {
    const row = await findRowByCodeAndDesc(exp.code, exp.description);

    if (!row) {
      await page.screenshot({
        path: `test-results/missing-statuscode-${exp.code}.png`,
        fullPage: false,
      }).catch(() => {});

      throw new Error(
        [
          '❌ E-Fatura Durum Kodu Bulunamadı',
          `Code        : ${exp.code}`,
          `Description : ${exp.description}`,
          `QueueStatus : ${exp.queueStatus}`,
        ].join('\n')
      );
    }

    const rowTextN = norm(await row.innerText());
    expect(rowTextN).toContain(norm(exp.code));
    expect(rowTextN).toContain(norm(exp.description));
    expect(rowTextN).toContain(norm(exp.queueStatus));
  }
});

test('@smoke E-Fatura Kod Eşleme sayfası validasyonlar', async ({ page }) => {
  test.setTimeout(6 * 60 * 1000);

  await page.goto(BC_BASE_URL, { waitUntil: 'networkidle' });
  const frame = page.frameLocator('iframe[title="undefined"]');

  await openMenu(frame);

  await frame.getByRole('menuitem', { name: /E-Fatura Kod Eşleme/i }).click();

  // ✅ Caption doğrulama (strict-safe)
  await expect(frame.locator('[id^="page-caption"]'))
    .toContainText(/E-Fatura Kod Eşleme:/i);

  const expectedRows = [
    { type: 'Para Birimi', source: 'TRY', destination: 'TRY', description: 'TRY' },
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
    { type: 'Ülke', source: 'SA', destination: 'SA', description: 'SAUDI ARABIA' },
    { type: 'Ülke', source: 'UK', destination: 'GB', description: 'İngiltere' },

    { type: 'UOM', source: 'NIU',   destination: 'NIU', description: 'ADET' },
    { type: 'UOM', source: 'ADET',  destination: 'NIU', description: 'ADET' },
    { type: 'UOM', source: 'KASA',  destination: 'NIU', description: 'KASA' },
    { type: 'UOM', source: 'METRE', destination: 'MTR', description: 'METRE' },
    { type: 'UOM', source: 'PAKET', destination: 'NIU', description: 'PAKET' },

    { type: 'EFat. Ödemek. Yöntem', source: 'BANKA', destination: '42', description: 'BANKA HAVALESİ' },
    { type: 'EFat. Ödemek. Yöntem', source: 'NAKIT', destination: '42', description: 'NAKIT ÖDEME' },
    { type: 'EFat. Ödemek. Yöntem', source: 'PEŞİN', destination: '42', description: 'PEŞİN' },

    { type: 'EAR. İnternet Ödemesi. Yöntem', source: 'BANKA',      destination: 'EFT/HAVALE',            description: 'EFT/HAVALE' },
    { type: 'EAR. İnternet Ödemesi. Yöntem', source: 'KREDİKARTI', destination: 'KREDIKARTI/BANKAKARTI', description: 'KREDİ KARTI' },
    { type: 'EAR. İnternet Ödemesi. Yöntem', source: 'NAKIT',      destination: 'DIGER',                 description: 'NAKIT ÖDEME' },
    { type: 'EAR. İnternet Ödemesi. Yöntem', source: 'PEŞİN',      destination: '42',                    description: 'PEŞİN' },
  ];

  const grid = await getGrid(frame);

  async function findRowByTypeAndSource(type, source, maxScrolls = 80) {
    const typeN = norm(type);
    const sourceN = norm(source);

    for (let i = 0; i < maxScrolls; i++) {
      const rows = grid.getByRole('row');
      const count = await rows.count();

      for (let r = 0; r < count; r++) {
        const row = rows.nth(r);
        const txtN = norm(await row.innerText().catch(() => ''));
        if (!txtN) continue;
        if (txtN.includes(typeN) && txtN.includes(sourceN)) return row;
      }

      await page.keyboard.press('PageDown');
      await page.waitForTimeout(150);
    }
    return null;
  }

  for (const exp of expectedRows) {
    const row = await findRowByTypeAndSource(exp.type, exp.source);

    if (!row) {
      await page.screenshot({
        path: `test-results/missing-mapping-${exp.type}-${exp.source}.png`,
        fullPage: false,
      }).catch(() => {});

      throw new Error(
        [
          '❌ Kod Eşleme Satırı Bulunamadı',
          `Type        : ${exp.type}`,
          `Source      : ${exp.source}`,
          `Destination : ${exp.destination}`,
          `Description : ${exp.description}`,
        ].join('\n')
      );
    }

    const rowTextN = norm(await row.innerText());
    expect(rowTextN).toContain(norm(exp.type));
    expect(rowTextN).toContain(norm(exp.source));
    expect(rowTextN).toContain(norm(exp.destination));
    expect(rowTextN).toContain(norm(exp.description));
  }
});
test('@smoke E-Fatura Vergi Türü Kodları sayfası validasyonlar', async ({ page }) => {
  test.setTimeout(8 * 60 * 1000);

  await page.goto(BC_BASE_URL, { waitUntil: 'networkidle' });
  const frame = page.frameLocator('iframe[title="undefined"]');

  // senin istediğin giriş adımları (openMenu yerine birebir)
  await frame.getByRole('menuitem', { name: 'Pargesoft E-Fatura' }).click();
  await expect(frame.getByRole('button', { name: 'Sabitle' })).toBeVisible();

  await frame.getByRole('menuitem', { name: 'Kurulum' }).click();
  await expect(frame.getByRole('menu', { name: 'Kurulum' })).toBeVisible();

  await frame.getByRole('menuitem', { name: /E-Fatura Vergi Türü Kodu/i }).click();

  // caption check (sayfa başlığın tam metni farklı olabilir)
  await expect(frame.locator('[id^="page-caption"]'))
    .toContainText(/E-Fatura Vergi Türü/i);

  const expectedRows = [
    { code: '0015', description: 'uuu', type: 'KDV', calcOrder: '0', rate: '20,00' },
    { code: '8001', description: 'Borsa Tescil Ücreti', type: 'KDV', calcOrder: '0', rate: '0,00' },
    { code: '8002', description: 'Enerji Fonu', type: 'KDV', calcOrder: '0', rate: '0,00' },
    { code: '8004', description: 'Trt Payı', type: 'KDV', calcOrder: '0', rate: '0,00' },
    { code: '8005', description: 'Elektrik Tüketim Vergisi', type: 'KDV', calcOrder: '0', rate: '0,00' },
    { code: '8006', description: 'Telsiz Kullanım Ücreti', type: 'KDV', calcOrder: '0', rate: '0,00' },
    { code: '8007', description: 'Telsiz Ruhsat Ücreti', type: 'KDV', calcOrder: '0', rate: '0,00' },
    { code: '8008', description: 'Çevre Temizlik Vergisi', type: 'KDV', calcOrder: '0', rate: '0,00' },

    { code: '801', description: 'Milli Piyango, Spor Toto vb. Oyunlar', type: 'Özel Matrah', calcOrder: '0', rate: '0,00' },
    { code: '802', description: 'At Yarışları ve Diğer Müşterek Bahis ve Talih Oyunları', type: 'Özel Matrah', calcOrder: '0', rate: '0,00' },
    { code: '803', description: 'Profesyonel Sanatçıların Yer Aldığı Gösteriler', type: 'Özel Matrah', calcOrder: '0', rate: '0,00' },
    { code: '804', description: 'Gümrük Depolarında ve Müzayede Mahallerinde Yapılan Satışlar', type: 'Özel Matrah', calcOrder: '0', rate: '0,00' },
    { code: '805', description: 'Altından Mamül veya Altın İçeren Ziynet Eşyaları', type: 'Özel Matrah', calcOrder: '0', rate: '0,00' },
    { code: '806', description: 'Tütün Mamülleri', type: 'Özel Matrah', calcOrder: '0', rate: '0,00' },
    { code: '807', description: 'Muzır Neşriyat Kapsamındaki Gazete, Dergi vb.', type: 'Özel Matrah', calcOrder: '0', rate: '0,00' },
    { code: '808', description: 'Gümüşten Mamul veya Gümüş İçeren Ziynet Eşyaları', type: 'Özel Matrah', calcOrder: '0', rate: '0,00' },
    { code: '809', description: 'Belediyeler Tarafından Yapılan Şehir', type: 'Özel Matrah', calcOrder: '0', rate: '0,00' },
    { code: '810', description: 'Ön Ödemeli Elektronik Haberleşme Hizmetleri', type: 'Özel Matrah', calcOrder: '0', rate: '0,00' },
    { code: '811', description: 'TŞOF Tarafından Araç Plakaları ile Sürücü Kurslarında Kullanılan Bir Kısım Evrakın Teslimi', type: 'Özel Matrah', calcOrder: '0', rate: '0,00' },
    { code: '812', description: 'KDV Uygulanmadan Alınan İkinci El Motorlu Kara Taşıtı veya Taşınmaz Teslimi', type: 'Özel Matrah', calcOrder: '0', rate: '0,00' },

    { code: '813', description: 'Çevre ve Bahçe Bakım Hizmetleri', type: 'Tevkifat', calcOrder: '0', rate: '100,00' },
    { code: '814', description: 'Servis Taşımacılığı Hizmeti', type: 'Tevkifat', calcOrder: '0', rate: '100,00' },
    { code: '815', description: 'Her Türlü Baskı ve Basım Hizmetleri', type: 'Tevkifat', calcOrder: '0', rate: '100,00' },
    { code: '816', description: 'Hurda Metalden Elde Edilen Külçe Teslimleri', type: 'Tevkifat', calcOrder: '0', rate: '100,00' },
    { code: '817', description: 'Bakır, Çinko, Demir Çelik, Alüminyum ve Kurşun Külçe Teslimi', type: 'Tevkifat', calcOrder: '0', rate: '100,00' },
    { code: '818', description: 'Bakır, Çinko, Alüminyum ve Kurşun Ürünlerinin Teslimi', type: 'Tevkifat', calcOrder: '0', rate: '100,00' },
    { code: '819', description: 'İstisnadan Vazgeçenlerin Hurda ve Atık Teslimi', type: 'Tevkifat', calcOrder: '0', rate: '100,00' },
    { code: '820', description: 'Metal, Plastik, Lastik, Kauçuk, Kâğıt ve Cam Hurda ve Atıklardan Elde Edilen Hammadde Teslimi[KDVGUT-(I/C-2.1.3.3.4)]', type: 'Tevkifat', calcOrder: '0', rate: '100,00' },
    { code: '821', description: 'Pamuk, Tiftik, Yün ve Yapağı İle Ham Post ve Deri Teslimleri', type: 'Tevkifat', calcOrder: '0', rate: '100,00' },
    { code: '822', description: 'Ağaç ve Orman Ürünleri Teslimi', type: 'Tevkifat', calcOrder: '0', rate: '100,00' },
    { code: '823', description: 'Yük Taşımacılığı Hizmeti', type: 'Tevkifat', calcOrder: '0', rate: '100,00' },
    { code: '824', description: 'Ticari Reklam Hizmetleri', type: 'Tevkifat', calcOrder: '0', rate: '100,00' },
    { code: '825', description: 'Demir-Çelik Ürünlerinin Teslimi', type: 'Tevkifat', calcOrder: '0', rate: '100,00' },

    { code: '9021', description: '4961 Banka Sigorta Muameleleri Vergisi', type: 'KDV', calcOrder: '0', rate: '0,00' },
    { code: '9040', description: 'Mera Fonu', type: 'KDV', calcOrder: '0', rate: '0,00' },
    { code: '9077', description: 'Motorlu Taşıt Araçlarına İlişkin Özel Tüketim Vergisi (Tescile Tabi Olanlar)', type: 'KDV', calcOrder: '0', rate: '0,00' },
  ];

  const grid = await getGrid(frame);

  async function findRowByCodeAndDesc(code, description, maxScrolls = 120) {
    const codeN = norm(code);
    const descN = norm(description);

    for (let i = 0; i < maxScrolls; i++) {
      const rows = grid.getByRole('row');
      const count = await rows.count();

      for (let r = 0; r < count; r++) {
        const row = rows.nth(r);
        const txtN = norm(await row.innerText().catch(() => ''));
        if (!txtN) continue;
        if (txtN.includes(codeN) && txtN.includes(descN)) return row;
      }

      await page.keyboard.press('PageDown');
      await page.waitForTimeout(150);
    }
    return null;
  }

  for (const exp of expectedRows) {
    const row = await findRowByCodeAndDesc(exp.code, exp.description);

    if (!row) {
      await page.screenshot({
        path: `test-results/missing-taxtype-${exp.code}.png`,
        fullPage: false,
      }).catch(() => {});

      throw new Error(
        [
          '❌ Vergi Türü Kodu satırı bulunamadı',
          `Code       : ${exp.code}`,
          `Desc       : ${exp.description}`,
          `Type       : ${exp.type}`,
          `CalcOrder  : ${exp.calcOrder}`,
          `Rate       : ${exp.rate}`,
        ].join('\n')
      );
    }

    const rowTextN = norm(await row.innerText());
    expect(rowTextN).toContain(norm(exp.code));
    expect(rowTextN).toContain(norm(exp.description));
    expect(rowTextN).toContain(norm(exp.type));
    expect(rowTextN).toContain(norm(exp.calcOrder));
    expect(rowTextN).toContain(norm(exp.rate));
  }
});
