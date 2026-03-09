import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 120 * 1000,

  // HTML report’u her koşulda üret
  reporter: [
    ['html', { open: 'never', outputFolder: 'playwright-report' }],
  
    ['list'],
  ],

  // Fail olunca screenshot/trace/video zaten doğru
  use: {
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
    video: 'retain-on-failure',
  },

  projects: [
    {
      name: 'setup',
      testMatch: /auth\.setup\.spec\.js/,
    },
    {
      name: 'chromium-tests',
      testMatch: /.*\.spec\.js/,
      testIgnore: [/auth\.setup\.spec\.js/, /api\/.*\.spec\.js/],
      use: {
        ...devices['Desktop Chrome'],
        storageState: 'storageState.json',
        headless: true, // CI’de bunu true yapmanı öneririm
      },
      dependencies: ['setup'],
    },
    {
      name: 'api',
      testMatch: /api\/.*\.spec\.js/,
      use: { baseURL: '', storageState: undefined },
    },
  ],
});
