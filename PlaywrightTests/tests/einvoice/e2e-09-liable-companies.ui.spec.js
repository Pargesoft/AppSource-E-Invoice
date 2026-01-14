import { test, expect } from "../../fixtures/bc.fixtures.js";
import { openLiableCompanies } from "../../flows/einvoice.flow.js";

test("@e2e @ui E2E-09 Liable Companies güncelleme ve cari etkisi", async ({ frame }) => {
  test.setTimeout(10 * 60 * 1000);

  await openLiableCompanies(frame);

  // TODO: Liable Companies grid'e satır ekle/sil UI otomasyonu
  await expect(frame.locator("body")).toContainText(/Liable Companies|Sorumlu/i);

  // TODO: Customer card açıp ilgili alan/flag etkisini assert et
});
