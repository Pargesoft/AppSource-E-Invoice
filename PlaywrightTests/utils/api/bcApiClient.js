// PlaywrightTests/utils/api/bcApiClient.js
import { request } from "@playwright/test";

export class BcApiClient {
  constructor({ baseUrl, accessToken, companyId }) {
    this.baseUrl = baseUrl;
    this.accessToken = accessToken;
    this.companyId = companyId; // GUID (sen env'de tutuyorsun)
    this.ctx = null;
  }

  async init() {
    this.ctx = await request.newContext({
      baseURL: this.baseUrl,
      extraHTTPHeaders: {
        Authorization: `Bearer ${this.accessToken}`,
        Accept: "application/json",
        "Content-Type": "application/json",
      },
    });
  }

  async dispose() {
    await this.ctx?.dispose();
  }

  async getCustomerByNumber(number) {
    const r = await this.ctx.get(`/companies(${this.companyId})/customers?$filter=number eq '${number}'`);
    if (!r.ok()) throw new Error(`GET customers failed: ${r.status()} ${await r.text()}`);
    return (await r.json()).value?.[0] ?? null;
  }

  async getItemByNumber(number) {
    const r = await this.ctx.get(`/companies(${this.companyId})/items?$filter=number eq '${number}'`);
    if (!r.ok()) throw new Error(`GET items failed: ${r.status()} ${await r.text()}`);
    return (await r.json()).value?.[0] ?? null;
  }

  async createSalesInvoice({ customerId, externalDocumentNumber }) {
    const r = await this.ctx.post(`/companies(${this.companyId})/salesInvoices`, {
      data: { customerId, externalDocumentNumber },
    });
    if (!r.ok()) throw new Error(`POST salesInvoices failed: ${r.status()} ${await r.text()}`);
    return await r.json(); // {id, number, ...}
  }

  async addSalesInvoiceLine(salesInvoiceId, { itemId, quantity = 1 }) {
    const r = await this.ctx.post(
      `/companies(${this.companyId})/salesInvoices(${salesInvoiceId})/salesInvoiceLines`,
      { data: { lineType: "Item", lineObjectId: itemId, quantity } }
    );
    if (!r.ok()) throw new Error(`POST salesInvoiceLines failed: ${r.status()} ${await r.text()}`);
    return await r.json();
  }
}
