// tests/auth.setup.spec.js
const { test } = require('@playwright/test');
const dotenv = require('dotenv');
const LoginPage = require('../../pages/LoginPage').default; // << FIX
dotenv.config();

const STORAGE_STATE = 'storageState.json';

test('Perform login and save storageState', async ({ page }) => {
  const BC_BASE_URL = process.env.BC_BASE_URL;
  const BC_USERNAME = process.env.BC_USERNAME;
  const BC_PASSWORD = process.env.BC_PASSWORD;
  const TOTP_SECRET = process.env.TOTP_SECRET;

  if (!BC_BASE_URL || !BC_USERNAME || !BC_PASSWORD || !TOTP_SECRET) {
    throw new Error('Env değişkenleri eksik. Lütfen .env dosyasını kontrol edin.');
  }

  const loginPage = new LoginPage(page);

  await loginPage.navigateToLogin(BC_BASE_URL);
  await loginPage.enterUsername(BC_USERNAME);
  await loginPage.enterPassword(BC_PASSWORD);
  await loginPage.enterTOTP(TOTP_SECRET);

  await page.context().storageState({ path: STORAGE_STATE });

  console.log('💾 storageState.json oluşturuldu.');
});
