import { test, expect } from "../../fixtures/hybrid.fixtures.js";
import { createSalesInvoiceViaApi } from "../../flows/dataFactory.flow.js";
import { openCodeMappingPage, openOutgoingQueue, expectRowExists } from "../../flows/einvoice.flow.js";

test("@e2e @hybrid E2E-03 Code Mapping yokken davranış", async ({ page, frame, bcApi }) => {
  test.setTimeout(10 * 60 * 1000);

  // Arrange: Mapping sayfasına git (UI) ve ilgili mapping'i sil (manual implement)
  await openCodeMappingPage(frame);

  // TODO: burada senin mapping grid kolonlarına göre satırı bulup "Delete" aksiyonu yazılacak.
  // Şimdilik iskelet:
  await expect(frame.locator("body")).toContainText(/Kod Eşleme|Mapping/i);

  // Arrange (API): invoice oluştur
  const { invoiceNo } = await createSalesInvoiceViaApi({
    bcApi,
    customerNo: "C10000",
    itemNo: "1896-S",
    qty: 1,
  });

  // Act (UI): Outgoing Queue → Send
  await openOutgoingQueue(frame);
  const row = await expectRowExists(frame, page, [invoiceNo]);
  await row.click();
  await frame.getByRole("button", { name: /Gönder|Send/i }).click();

  // Assert: Mapping yoksa hata beklenir (tenant mesajına göre regexi ayarlarsın)
  await expect(frame.locator("body")).toContainText(/Mapping|Eşleme|Hata|Error|Eksik/i);
});

test("@e2e @hybrid E2E-03 Code Mapping varken davranış", async ({ page, frame, bcApi }) => {
  test.setTimeout(10 * 60 * 1000);

  // Arrange: Mapping ekle (UI)
  await openCodeMappingPage(frame);

  // TODO: mapping create UI otomasyonu yazılacak
  await expect(frame.locator("body")).toContainText(/Kod Eşleme|Mapping/i);

  // Arrange (API): invoice oluştur
  const { invoiceNo } = await createSalesInvoiceViaApi({
    bcApi,
    customerNo: "C10000",
    itemNo: "1896-S",
    qty: 1,
  });

  // Act (UI): Outgoing Queue → Send
  await openOutgoingQueue(frame);
  const row = await expectRowExists(frame, page, [invoiceNo]);
  await row.click();
  await frame.getByRole("button", { name: /Gönder|Send/i }).click();

  // Assert: success
  await expect(frame.locator("body")).toContainText(/Başarılı|Success|Gönderildi|Sent/i);
});
