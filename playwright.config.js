// playwright.config.js
// CommonJS stilinde config
const { defineConfig, devices } = require('@playwright/test');

module.exports = defineConfig({
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
        headless: false,                   // UI'ı görmek için
      },
      // Bu project, önce 'setup' project’ini çalıştırır
      dependencies: ['setup'],
    },

    // 3) API testleri: setup’a bağlı değil, storageState kullanmıyor
    {
      name: 'api',
      testMatch: /api\/.*\.spec\.js/, // tests/api/... altındaki tüm *.spec.js
      use: {
        // browser açmasak da olur, ama request fixture’ı için project tanımlı
        baseURL: '',
        storageState: undefined,
      },
    },
  ],
});
