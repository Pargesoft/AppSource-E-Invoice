// PlaywrightTests/utils/bc/bc.frame.js
import { expect } from "@playwright/test";

export async function getBCFrame(page) {
  // If we are not logged into BC yet, iframe will never appear.
  await page.locator("iframe").first().waitFor({ state: "attached", timeout: 60_000 });

  const iframeHandle = await page.locator("iframe").first().elementHandle();
  const frame = await iframeHandle.contentFrame();

  if (!frame) {
    await page.screenshot({ path: "bc-iframe-no-contentframe.png", fullPage: true }).catch(() => {});
    throw new Error("BC iframe bulundu ama contentFrame alınamadı. 'bc-iframe-no-contentframe.png' kontrol et.");
  }

  return frame; // ✅ Playwright Frame
}

export async function expectBCReady(frame) {
  // Role/profile bağımsız "BC hazır" sinyali
  const caption = frame.locator('[id^="page-caption"]').first();
  const anyGrid = frame.getByRole("grid").first();
  const anyForm = frame.getByRole("form").first();

  await expect(caption.or(anyGrid).or(anyForm)).toBeVisible({ timeout: 60_000 });
}
