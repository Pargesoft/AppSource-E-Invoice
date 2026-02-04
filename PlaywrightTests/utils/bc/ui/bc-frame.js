import { expect } from "@playwright/test";

/**
 * ✅ Business Central main content frame’i güvenli şekilde bulur.
 * Öncelik:
 *  1) name=MainContent
 *  2) URL BC + UI sinyalleri (menuitem / page-caption / grid)
 */
export async function getBcFrame(page, { timeoutMs = 60000 } = {}) {
  const started = Date.now();

  while (Date.now() - started < timeoutMs) {
    const main = page.frame({ name: "MainContent" });
    if (main) return main;

    for (const f of page.frames()) {
      const url = f.url() || "";
      const isLikelyBc =
        /businesscentral\.dynamics\.com/i.test(url) ||
        /\/Core/i.test(url) ||
        /\/Sandbox/i.test(url);

      if (!isLikelyBc) continue;

      try {
        if ((await f.getByRole("menuitem").first().count()) > 0) return f;
      } catch {}

      try {
        if ((await f.locator('[id^="page-caption"]').first().count()) > 0) return f;
      } catch {}

      try {
        if ((await f.locator('[role="grid"]').first().count()) > 0) return f;
      } catch {}
    }

    await page.waitForTimeout(250);
  }

  const urls = page.frames().map((f) => f.url()).filter(Boolean);
  throw new Error(`❌ BC main frame bulunamadı (${timeoutMs}ms).\n- ${urls.join("\n- ")}`);
}

/**
 * ✅ Role Center hazır mı?
 * En stabil sinyal: menuitem render
 */
export async function expectRoleCenterReady(frame, { timeoutMs = 60000 } = {}) {
  await expect(frame.getByRole("menuitem").first()).toBeVisible({ timeout: timeoutMs });
}
