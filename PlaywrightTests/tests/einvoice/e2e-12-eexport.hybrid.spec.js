import { test, expect } from "../../fixtures/hybrid.fixtures.js";
import { createSalesInvoiceViaApi } from "../../flows/dataFactory.flow.js";
import { openEExportSetup } from "../../flows/einvoice.flow.js";

test("@e2e @hybrid E2E-12 E-İhracat setup + invoice", async ({ frame, bcApi }) => {
  test.setTimeout(12 * 60 * 1000);

  // UI: E-İhracat setup
  await openEExportSetup(frame);
  await expect(frame.locator("body")).toContainText(/E-İhracat|Export/i);

  // TODO: Setup alanlarını doldur + save + toast

  // API: invoice oluştur (e-ihracat için gerekiyorsa customer/item farklı olabilir)
  const { invoiceNo } = await createSalesInvoiceViaApi({
    bcApi,
    customerNo: "C10000",
    itemNo: "1896-S",
    qty: 1,
  });

  // TODO: UI’da bu invoice’u e-ihracat akışına sok (queue/send)
  await expect(frame.locator("body")).toContainText(new RegExp(invoiceNo, "i"));
});
