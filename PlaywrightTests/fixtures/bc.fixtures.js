// PlaywrightTests/fixtures/bc.fixtures.js
import { test as base, expect } from "@playwright/test";
import { BC_BASE_URL } from "../utils/env.js";
import { getBCFrame } from "../utils/bc/bc.frame.js";

export const test = base.extend({
  frame: async ({ page }, use) => {
    await page.goto(BC_BASE_URL, { waitUntil: "domcontentloaded" });
    const frame = getBCFrame(page);
    await use(frame);
  },
});

export { expect };
