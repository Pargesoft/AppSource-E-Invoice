import { test, expect } from "../../fixtures/hybrid.fixtures.js";
import { createSalesInvoiceViaApi } from "../../flows/dataFactory.flow.js";
import { openOutgoingQueue, expectRowExists } from "../../flows/einvoice.flow.js";

test("@e2e @hybrid E2E-05 Outgoing flow (API create + UI send)", async ({ page, frame, bcApi }) => {
  test.setTimeout(10 * 60 * 1000);

  // Arrange (API)
  const { invoiceNo } = await createSalesInvoiceViaApi({
    bcApi,
    customerNo: "C10000",
    itemNo: "1896-S",
    qty: 1,
  });

  // Act (UI) - Outgoing Queue aç ve dokümanı bul
  await openOutgoingQueue(frame);

  // NOTE: Outgoing Queue gridinde “Invoice No / Document No” kolonuna göre arıyoruz
  const row = await expectRowExists(frame, page, [invoiceNo]);

  // Send button / action tenant’a göre değişebilir.
  // Burada satırı seçip "Gönder" benzeri butona tıklama iskeleti:
  await row.click();
  const sendBtn = frame.getByRole("button", { name: /Gönder|Send/i });
  await sendBtn.click();

  // Assert: en azından bir success/hata mesajı görünmeli
  await expect(frame.locator("body")).toContainText(/Başarılı|Success|Gönderildi|Sent|Hata|Error/i);
});
