// PlaywrightTests/tests/auth.setup.spec.js
import { test } from '@playwright/test';
import LoginPage from '../../pages/LoginPage.js';
import {
  BC_BASE_URL,
  BC_USERNAME,
  BC_PASSWORD,
  TOTP_SECRET,
  STORAGE_STATE,
} from '../../utils/env.js';

test('Perform login and save storageState', async ({ page }) => {
  const loginPage = new LoginPage(page);

  await loginPage.navigateToLogin(BC_BASE_URL);
  await loginPage.enterUsername(BC_USERNAME);
  await loginPage.enterPassword(BC_PASSWORD);
  await loginPage.enterTOTP(TOTP_SECRET);

  await page.context().storageState({ path: STORAGE_STATE });

  console.log('💾 storageState.json oluşturuldu.');
});
