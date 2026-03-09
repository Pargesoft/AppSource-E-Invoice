import { test, expect } from "@playwright/test";
import { BC_BASE_URL } from "../../utils/env.js";
import { createSalesInvoiceUI } from "../../utils/bc/ui/sales-invoice.ui.js";

import {
  postInvoiceAndCloseDialogs,
  openOutgoingEInvoiceList,
  createOutgoingEInvoiceQueue,
  sortOutgoingQueueByEntryNoDesc,
  sendOutgoingEInvoice,
  queryOutgoingEInvoiceStatusAndExpectApproved,
} from "../../utils/bc/ui/einvoice-outgoing.ui.js";

test("@smoke E-Fatura Giden Fatura Oluşturma E-Arşiv - Customer 120.01.001.0001", async ({ page }) => {
  test.setTimeout(6 * 60 * 1000);

  await page.goto(BC_BASE_URL, { waitUntil: "domcontentloaded" });
  await page.waitForURL(/businesscentral\.dynamics\.com/i, { timeout: 60000 });

  const { invoiceNo, externalDocumentNo } = await createSalesInvoiceUI(page, {
    customerNo: "120.01.001.0001",
    itemNo: "MAD0000003",
    quantity: 1,
    unitPrice: 400,
    doPost: false,
  });

  expect(externalDocumentNo).toMatch(/^EXT-\d{5,7}$/);

  console.log("🧾 UI Invoice No :", invoiceNo || "(not captured)");
  console.log("📄 External Doc :", externalDocumentNo);

  await postInvoiceAndCloseDialogs(page);
  await openOutgoingEInvoiceList(page);

  await createOutgoingEInvoiceQueue(page, {
    noFilter: "satışlar",
    postDateFilter: "b",
  });

  await sortOutgoingQueueByEntryNoDesc(page);
  await sendOutgoingEInvoice(page);
  await queryOutgoingEInvoiceStatusAndExpectApproved(page, {
  expectedDocType: "E-Arşiv",
  });
});

test("@smoke E-Fatura Giden Fatura Oluşturma E-Fatura - Customer 120.01.001.0003", async ({ page }) => {
  test.setTimeout(6 * 60 * 1000);

  await page.goto(BC_BASE_URL, { waitUntil: "domcontentloaded" });
  await page.waitForURL(/businesscentral\.dynamics\.com/i, { timeout: 60000 });

  const { invoiceNo, externalDocumentNo } = await createSalesInvoiceUI(page, {
    customerNo: "120.01.001.0003",
    itemNo: "MAD0000003",
    quantity: 1,
    unitPrice: 400,
    doPost: false,
  });

  expect(externalDocumentNo).toMatch(/^EXT-\d{5,7}$/);

  console.log("🧾 UI Invoice No :", invoiceNo || "(not captured)");
  console.log("📄 External Doc :", externalDocumentNo);

  await postInvoiceAndCloseDialogs(page);
  await openOutgoingEInvoiceList(page);

  await createOutgoingEInvoiceQueue(page, {
    noFilter: "satışlar",
    postDateFilter: "b",
  });

  await sortOutgoingQueueByEntryNoDesc(page);
  await sendOutgoingEInvoice(page);
  await queryOutgoingEInvoiceStatusAndExpectApproved(page, {
  expectedDocType: "E-Fatura",
});
});