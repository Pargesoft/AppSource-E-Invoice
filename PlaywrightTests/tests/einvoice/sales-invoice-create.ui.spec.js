// PlaywrightTests/tests/einvoice/sales-invoice-create.ui.spec.js
import { test, expect } from "@playwright/test";
import { BC_BASE_URL } from "../../utils/env.js";
import { createSalesInvoiceUI } from "../../utils/bc/ui/sales-invoice.ui.js";

// ✅ yeni helper'lar (sen ayrı oluşturdum dedin)
import {
  postInvoiceAndCloseDialogs,
  openOutgoingEInvoiceList,
  createOutgoingEInvoiceQueue,
  sortOutgoingQueueByEntryNoDesc,
  sendOutgoingEInvoice,
  queryOutgoingEInvoiceStatusAndExpectApproved,
} from "../../utils/bc/ui/einvoice-outgoing.ui.js";

test("@smoke E-Fatura Giden Fatura Oluşturma E-Arşiv", async ({ page }) => {
  test.setTimeout(6 * 60 * 1000);

  await page.goto(BC_BASE_URL, { waitUntil: "domcontentloaded" });
  await page.waitForURL(/businesscentral\.dynamics\.com/i, { timeout: 60000 });

  const { invoiceNo, externalDocumentNo } = await createSalesInvoiceUI(page, {
    customerNo: "120.01.001.0001",
    itemNo: "MAD0000003",
    quantity: 1,
    unitPrice: 400,
    doPost: false, // Post'u aşağıdaki adımlarda yapacağız
  });

  // ✅ EXT- + 5..7 digit (total 9..11 chars)
  expect(externalDocumentNo).toMatch(/^EXT-\d{5,7}$/);

  console.log("🧾 UI Invoice No :", invoiceNo || "(not captured)");
  console.log("📄 External Doc :", externalDocumentNo);

  // ---------------------------
  // Adımlar
  // ---------------------------

  // 1) Deftere Naklet (Post) -> Evet -> "Fatura,..." dialogu -> Hayır
  await postInvoiceAndCloseDialogs(page);

  // 2) TellMe ile "E-Fatura Giden Faturalar" sayfasına git
  await openOutgoingEInvoiceList(page);

  // 3) Gönderim -> E-fatura Oluştur (G/M Kaydı Kullan + filtreler)
  await createOutgoingEInvoiceQueue(page, {
    noFilter: "satışlar",
    postDateFilter: "b",
  });

  // 4) Giriş No -> Azalan sırala
  await sortOutgoingQueueByEntryNoDesc(page);

  // 5) Gönderim -> Gönder -> Tamam
  await sendOutgoingEInvoice(page);

  // 6) Gönderim -> Durum Sorgula -> "Onaylandı" İlk sefer olmadıysa tekrar dene bekle
  await queryOutgoingEInvoiceStatusAndExpectApproved(page);
});
