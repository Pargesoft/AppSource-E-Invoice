// PlaywrightTests/utils/bc/bc.grid.js
import { expect } from "@playwright/test";
import { normalizeText } from "./bc.text.js";

export async function getGrid(frame) {
  const grid = frame.locator('[role="grid"]:has([role="gridcell"])').first();
  await expect(grid).toBeVisible({ timeout: 30_000 });
  await grid.click().catch(() => {});
  return grid;
}

// ✅ Grid’i en üste al (her aramada baştan başlasın)
export async function resetGridToTop({ page, grid }) {
  await grid.click().catch(() => {});
  await page.keyboard.press("Home").catch(() => {});
  await page.waitForTimeout(80); // virtualization settle (kontrollü ve kısa)
}

export async function findRowByContainsAll({
  page,
  grid,
  mustContain = [],
  maxScrolls = 40,
  waitMs = 80,
}) {
  const must = mustContain.map(normalizeText);

  for (let i = 0; i < maxScrolls; i++) {
    const rows = grid.getByRole("row");
    const count = await rows.count();

    for (let r = 0; r < count; r++) {
      const row = rows.nth(r);
      const txtN = normalizeText(await row.innerText().catch(() => ""));
      if (!txtN) continue;

      const ok = must.every((m) => txtN.includes(m));
      if (ok) return row;
    }

    await page.keyboard.press("PageDown");
    await page.waitForTimeout(waitMs);
  }

  return null;
}
