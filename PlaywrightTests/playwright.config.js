// playwright.config.js
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./PlaywrightTests/tests",
  timeout: 120 * 1000,

  reporter: [
    ["html", { open: "never", outputFolder: "playwright-report" }],
    ["list"],
  ],

  use: {
    screenshot: "only-on-failure",
    trace: "retain-on-failure",
    video: "retain-on-failure",
  },

  projects: [
    {
      name: "setup",
      testMatch: /auth\.setup\.spec\.js/,
    },
    {
      name: "ui",
      testMatch: [/.*\.ui\.spec\.js/, /.*\.spec\.js/],
      testIgnore: [/auth\.setup\.spec\.js/, /.*\.hybrid\.spec\.js/],
      use: {
        ...devices["Desktop Chrome"],
        storageState: "storageState.json",
        headless: true,
      },
      dependencies: ["setup"],
    },
    {
      name: "hybrid",
      testMatch: /.*\.hybrid\.spec\.js/,
      use: {
        ...devices["Desktop Chrome"],
        storageState: "storageState.json",
        headless: true,
      },
      dependencies: ["setup"],
    },
  ],
});
