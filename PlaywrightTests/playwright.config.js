// PlaywrightTests/playwright.config.js (update)
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',

  // Global timeout (gerekirse)
  timeout: 120 * 1000,

  // <-- add default artifact capture for CI
  use: {
    screenshot: 'only-on-failure',      // automatically save screenshots for failed tests
    trace: 'retain-on-failure',         // saves traces for failed tests (useful with Playwright Trace Viewer)
    video: 'retain-on-failure',         // saves video for failed tests
  },

  projects: [
    {
      name: 'setup',
      testMatch: /auth\.setup\.spec\.js/,
      // inherits default `use` above
    },
    {
      name: 'chromium-tests',
      testMatch: /.*\.spec\.js/,
      testIgnore: [
        /auth\.setup\.spec\.js/,
        /api\/.*\.spec\.js/,
      ],
      use: {
        ...devices['Desktop Chrome'],
        storageState: 'storageState.json',
        headless: false,
      },
      dependencies: ['setup'],
    },
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