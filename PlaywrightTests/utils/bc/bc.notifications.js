// PlaywrightTests/utils/bc/bc.notifications.js
import { expect } from "@playwright/test";

/**
 * BC toast/messages differ per tenant/extension.
 * We keep it flexible: look for common notification containers.
 */
export async function expectSomeSuccess(frame) {
  const toast = frame.locator('[role="status"], [class*="notification"], [class*="toast"]').first();
  await expect(toast).toBeVisible({ timeout: 30_000 });
}

export async function expectTextAppears(frame, textRegex) {
  await expect(frame.locator("body")).toContainText(textRegex, { timeout: 30_000 });
}
