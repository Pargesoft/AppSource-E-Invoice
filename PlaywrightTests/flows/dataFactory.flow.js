// PlaywrightTests/flows/dataFactory.flow.js
export async function createSalesInvoiceViaApi({ bcApi, customerNo, itemNo, qty = 1 }) {
  const customer = await bcApi.getCustomerByNumber(customerNo);
  if (!customer) throw new Error(`Customer not found: ${customerNo}`);

  const item = await bcApi.getItemByNumber(itemNo);
  if (!item) throw new Error(`Item not found: ${itemNo}`);

  const invoice = await bcApi.createSalesInvoice({
    customerId: customer.id,
    externalDocumentNumber: `PW-${Date.now()}`,
  });

  await bcApi.addSalesInvoiceLine(invoice.id, {
    itemId: item.id,
    quantity: qty,
  });

  return {
    invoiceId: invoice.id,
    invoiceNo: invoice.number, // ✅ “doküman kodu” burada
  };
}
