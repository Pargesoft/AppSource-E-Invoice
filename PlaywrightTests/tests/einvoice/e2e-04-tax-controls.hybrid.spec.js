import { test, expect } from "../../fixtures/hybrid.fixtures.js";
import { openTaxCodesPage } from "../../flows/einvoice.flow.js";

test("@e2e @hybrid E2E-04 Tax codes UI kontrolleri", async ({ frame }) => {
  test.setTimeout(10 * 60 * 1000);

  // UI: Vergi Türü Kodları sayfası kontrol (senin mevcut einvoice-setup.spec.js içindeki logic bunun için iyi)
  await openTaxCodesPage(frame);

  await expect(frame.locator('[id^="page-caption"]'))
    .toContainText(/Vergi Türü/i);
});
