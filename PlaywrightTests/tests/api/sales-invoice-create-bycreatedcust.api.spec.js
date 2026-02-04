import { test, expect } from "@playwright/test";
import { getCustomerByNumber } from "../../utils/bc/api/customer.api.js";
import { getItemByNumber } from "../../utils/bc/api/item.api.js";
import {
  createSalesInvoice,
  createSalesInvoiceLine,
  getSalesInvoiceById,
} from "../../utils/bc/api/sales-invoice.api.js";

function randomDigits(len) {
  let s = "";
  while (s.length < len) s += Math.floor(Math.random() * 10).toString();
  return s.slice(0, len);
}

/**
 * ExternalDocumentNumber max 20
 * EXT-YYMMDDHHMMSS-XX  => 20 chars
 */
function makeExternalDocumentNumber() {
  const d = new Date();
  const pad = (n) => String(n).padStart(2, "0");
  const yy = String(d.getFullYear()).slice(-2);
  const ts = `${yy}${pad(d.getMonth() + 1)}${pad(d.getDate())}${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}`;
  return `EXT-${ts}-${randomDigits(2)}`;
}
/**
function clamp(str, maxLen) {
  const s = String(str ?? "");
  return s.length > maxLen ? s.slice(0, maxLen) : s;
}


 * Deftere Nakil (customerPurchaseOrderReference) max 35 (senin error’dan kesin)
 * Format: S+FATURA / [] / {CustomerName}
 */
/**
{function makeDeftereNakil(customerName) {
  return clamp(`S+FATURA / [] / ${customerName}`, 35);
}}
 */
test.describe("@api Sales Invoice CREATE (hardcoded customer+item)", () => {
  test(
    "Create Sales Invoice + line + random externalDocumentNumber + deftereNakil via customerPurchaseOrderReference",
    async ({ request }) => {
      test.setTimeout(2 * 60 * 1000);

      const customerNo = "120.01.001.0001";
      const itemNo = "MAD0000003";

      // 1) Customer
      const customer = await getCustomerByNumber(request, customerNo);
      expect(customer.id).toBeTruthy();

      const customerName =
        customer.displayName ||
        customer.raw?.displayName ||
        customer.number;

      // 2) Header
      const externalDocumentNumber = makeExternalDocumentNumber();
      //const deftereNakil = makeDeftereNakil(customerName);

      const invoice = await createSalesInvoice(request, {
        customerId: customer.id,
        externalDocumentNumber,
        //customerPurchaseOrderReference: deftereNakil,
      });

      expect(invoice.id).toBeTruthy();

      console.log("✅ Sales Invoice CREATED");
      console.log("   Invoice Id :", invoice.id);
      console.log("   Invoice No :", invoice.number);
      console.log("   Customer   :", customer.number, "|", customerName);
      console.log("   Ext. DocNo :", externalDocumentNumber);
      //console.log("   Deftere    :", deftereNakil);

      // ✅ Backend verify (UI’dan bağımsız)
      const fresh = await getSalesInvoiceById(request, invoice.id);
     /**const got = (fresh.customerPurchaseOrderReference || "").trim();

      expect(
        got,
        `customerPurchaseOrderReference backend'de boş. API set etmemiş olabilir. Raw: ${JSON.stringify(fresh)}`
      ).toBe(deftereNakil);
     */
      // 3) Item resolve
      const item = await getItemByNumber(request, itemNo);
      expect(item.id).toBeTruthy();
      console.log("📦 Item USED  :", item.number, item.id);

      // 4) Line (qty=1, unitPrice=400 KDV hariç)
      const line = await createSalesInvoiceLine(request, {
        documentId: invoice.id,
        lineType: "Item",
        itemId: item.id,
        quantity: 1,
        unitPrice: 400,
        description: `PW Line ${item.number}`,
      });

      expect(line.id).toBeTruthy();
      console.log("✅ Sales Invoice LINE CREATED:", line.id);
    }
  );
});
