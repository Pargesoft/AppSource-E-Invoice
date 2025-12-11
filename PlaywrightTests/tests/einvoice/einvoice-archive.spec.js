// PlaywrightTests/tests/einvoice/einvoice-archive.spec.js
import { test, expect } from '@playwright/test';
import { BC_BASE_URL } from '../../utils/env.js'; // path'i senin yapına göre ayarladık

test('@smoke BC ana sayfa + Bank List ekranı testleri', async ({ page }) => {
  await page.goto(BC_BASE_URL, { waitUntil: 'networkidle' });

  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(15_000);

  console.log('✔ BC ana sayfa açıldı.');

  for (const frame of page.frames()) {
    console.log('FRAME:', { name: frame.name(), url: frame.url() });
  }

  const frame = page.frameLocator('iframe[title="undefined"]');

  await frame.getByRole('menuitem', { name: 'Pargesoft Localization' }).click();
  await frame.getByLabel('Bank-Branch').click();
  await frame.getByLabel('Bank List').click();

  const bankNameTextbox = frame.getByRole('textbox', {
    name: 'Bank Name, sorted in Ascending order',
    exact: true,
  });

  await bankNameTextbox.click();

  await expect(bankNameTextbox).toBeVisible();
  await expect(frame.getByText('Bank List:')).toBeVisible();
  await expect(frame.getByTitle('Go to role centre')).toBeVisible();
  await expect(frame.getByLabel('AKBANK T.A.Ş')).toContainText('AKBANK T.A.Ş.');
  await expect(frame.locator('#page-captionb8s')).toHaveText('Bank List:');

  console.log('✔ Bank List ekranı başarıyla test edildi.');
});
