// playwright.config.js (ESM)

import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',

  // Global timeout (gerekirse)
  timeout: 120 * 1000,

  projects: [
    // 1) Sadece auth.setup.spec.js çalışsın (storageState üretmek için)
    {
      name: 'setup',
      testMatch: /auth\.setup\.spec\.js/,
    },

    // 2) UI testleri: storageState.json ile çalışacaklar
    {
      name: 'chromium-tests',
      testMatch: /.*\.spec\.js/,
      // auth.setup + API testleri bu projede koşmasın:
      testIgnore: [
        /auth\.setup\.spec\.js/,
        /api\/.*\.spec\.js/,
      ],
      use: {
        ...devices['Desktop Chrome'],
        storageState: 'storageState.json', // ← BC login state buradan geliyor
        headless: false,
      },
      // Bu project, önce 'setup' projesini çalıştırır
      dependencies: ['setup'],
    },

    // 3) API testleri: setup’a bağlı değil, storageState kullanmıyor
    {
      name: 'api',
      testMatch: /api\/.*\.spec\.js/,
      use: {
        baseURL: '',
        storageState: undefined,
      },
    },
  ],
});
