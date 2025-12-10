// tests/einvoice/einvoice-archive.spec.js
import { test, expect } from '@playwright/test';
import dotenv from 'dotenv';

dotenv.config();

test('@smoke BC ana sayfa + Bank List ekranı testleri', async ({ page }) => {
  const baseUrl = process.env.BC_BASE_URL;
  if (!baseUrl) {
    throw new Error('BC_BASE_URL .env içinde tanımlı değil');
  }

  // 1) Business Central ana sayfasına git
  await page.goto(baseUrl, { waitUntil: 'networkidle' });

  // 2) Ana sayfanın tam oturması için bekleme
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(15_000); // 15 saniye

  console.log("✔ BC ana sayfa açıldı.");

  // 3) DEBUG: Frame loglama
  for (const frame of page.frames()) {
    console.log('FRAME:', {
      name: frame.name(),
      url: frame.url(),
    });
  }

  // 4) İçerik iframe’ini bul (BC sayfalarında genelde runinframe=1 kullanılır)
  const mainFrameLocator = page.frameLocator('iframe[src*="runinframe=1"]');

  // Eğer runinframe yoksa fallback olarak title="undefined" olan iframe’i bulalım
  const frame = page.frameLocator('iframe[title="undefined"]');

  // --- BANK LIST TESTİNİ EKLEDİM ---

  // 5) "Pargesoft Localization" menüsüne tıkla
  await frame
    .getByRole('menuitem', { name: 'Pargesoft Localization' })
    .click();

  // 6) Bank-Branch menüsüne tıkla
  await frame.getByLabel('Bank-Branch').click();

  // 7) Bank List aç
  await frame.getByLabel('Bank List').click();

  // 8) Bank Name textbox’a tıkla
  const bankNameTextbox = frame.getByRole('textbox', {
    name: 'Bank Name, sorted in Ascending order',
    exact: true,
  });

  await bankNameTextbox.click();

  // 9) Kontroller
  await expect(bankNameTextbox).toBeVisible();
  await expect(frame.getByText('Bank List:')).toBeVisible();
  await expect(frame.getByTitle('Go to role centre')).toBeVisible();
  await expect(frame.getByLabel('AKBANK T.A.Ş')).toContainText('AKBANK T.A.Ş.');

  // 10) Aria snapshot kontrolü
  await expect(frame.locator('#page-captionb8s')).toHaveText('Bank List:');

  

  console.log("✔ Bank List ekranı başarıyla test edildi.");
});
