// PlaywrightTests/utils/bc/sales-invoice.api.js
import { expect } from "@playwright/test";
import { getAccessToken } from "../../get-token.js";
import { BC_COMPANY_ID, BC_ENVIRONMENT, BC_TENANT_ID } from "../../env.js";

/* ----------------------------- helpers ----------------------------- */

function requireApiEnv() {
  if (!BC_TENANT_ID) throw new Error("Env eksik: BC_TENANT_ID");
  if (!BC_ENVIRONMENT) throw new Error("Env eksik: BC_ENVIRONMENT");
  if (!BC_COMPANY_ID) throw new Error("Env eksik: BC_COMPANY_ID");
}

function buildApiBaseUrl() {
  requireApiEnv();
  return `https://api.businesscentral.dynamics.com/v2.0/${BC_TENANT_ID}/${BC_ENVIRONMENT}/api/v2.0`;
}

async function authHeaders(request) {
  const token = await getAccessToken(request);
  return {
    Authorization: `Bearer ${token}`,
    Accept: "application/json",
    "Content-Type": "application/json",
  };
}

/* ----------------------------- API methods ----------------------------- */

/**
 * CREATE Sales Invoice (Header)
 * POST /companies({companyId})/salesInvoices
 *
 * ✅ Standard API field set:
 * - customerId (required)
 * - externalDocumentNumber (optional)
 * - customerPurchaseOrderReference (optional)  <-- UI'da "Müşteri Satınalma Sipariş No." gibi görünebilir
 *
 * ❌ postingDescription yok (400 verir)
 */
export async function createSalesInvoice(
  request,
  { customerId, externalDocumentNumber, customerPurchaseOrderReference } = {}
) {
  if (!customerId) throw new Error("createSalesInvoice: customerId zorunlu");

  const baseUrl = buildApiBaseUrl();
  const headers = await authHeaders(request);

  const payload = { customerId };
  if (externalDocumentNumber) payload.externalDocumentNumber = externalDocumentNumber;
  //if (customerPurchaseOrderReference)
   // payload.customerPurchaseOrderReference = customerPurchaseOrderReference;

  const res = await request.post(
    `${baseUrl}/companies(${BC_COMPANY_ID})/salesInvoices`,
    { headers, data: payload }
  );

  const bodyText = await res.text().catch(() => "");
  expect(res.ok(), `Create SalesInvoice failed: ${res.status()} ${bodyText}`).toBeTruthy();

  const json = bodyText ? JSON.parse(bodyText) : {};
  return {
    id: json.id,
    number: json.number,
    customerId: json.customerId,
    externalDocumentNumber: json.externalDocumentNumber,
    //customerPurchaseOrderReference: json.customerPurchaseOrderReference,
    raw: json,
  };
}

/**
 * GET Sales Invoice by Id (backend verify)
 * GET /companies({companyId})/salesInvoices({invoiceId})
 */
export async function getSalesInvoiceById(request, invoiceId) {
  if (!invoiceId) throw new Error("getSalesInvoiceById: invoiceId zorunlu");

  const baseUrl = buildApiBaseUrl();
  const headers = await authHeaders(request);

  const res = await request.get(
    `${baseUrl}/companies(${BC_COMPANY_ID})/salesInvoices(${invoiceId})`,
    { headers }
  );

  const bodyText = await res.text().catch(() => "");
  expect(res.ok(), `Get SalesInvoice failed: ${res.status()} ${bodyText}`).toBeTruthy();

  return bodyText ? JSON.parse(bodyText) : {};
}

/**
 * PATCH Sales Invoice
 * PATCH /companies({companyId})/salesInvoices({invoiceId})
 *
 * Not: her field editable olmayabilir.
 */
export async function updateSalesInvoice(request, invoiceId, patch = {}) {
  if (!invoiceId) throw new Error("updateSalesInvoice: invoiceId zorunlu");
  if (!patch || typeof patch !== "object")
    throw new Error("updateSalesInvoice: patch object zorunlu");

  const baseUrl = buildApiBaseUrl();
  const headers = await authHeaders(request);

  const res = await request.patch(
    `${baseUrl}/companies(${BC_COMPANY_ID})/salesInvoices(${invoiceId})`,
    {
      headers: { ...headers, "If-Match": "*" },
      data: patch,
    }
  );

  const bodyText = await res.text().catch(() => "");
  const ok = res.status() === 200 || res.status() === 204;

  return { ok, status: res.status(), bodyText };
}

/**
 * CREATE Sales Invoice Line
 * POST /companies({companyId})/salesInvoices({invoiceId})/salesInvoiceLines
 */
export async function createSalesInvoiceLine(
  request,
  { documentId, lineType, itemId, accountId, quantity, unitPrice, description } = {}
) {
  if (!documentId) throw new Error("createSalesInvoiceLine: documentId zorunlu");
  if (!lineType) throw new Error("createSalesInvoiceLine: lineType zorunlu (Item/Account)");
  if (!itemId && !accountId)
    throw new Error("createSalesInvoiceLine: itemId veya accountId zorunlu");

  const baseUrl = buildApiBaseUrl();
  const headers = await authHeaders(request);

  const payload = { lineType };
  if (itemId) payload.itemId = itemId;
  if (accountId) payload.accountId = accountId;
  if (quantity !== undefined) payload.quantity = quantity;
  if (unitPrice !== undefined) payload.unitPrice = unitPrice;
  if (description) payload.description = description;

  const res = await request.post(
    `${baseUrl}/companies(${BC_COMPANY_ID})/salesInvoices(${documentId})/salesInvoiceLines`,
    { headers, data: payload }
  );

  const bodyText = await res.text().catch(() => "");
  expect(res.ok(), `Create SalesInvoiceLine failed: ${res.status()} ${bodyText}`).toBeTruthy();

  const json = bodyText ? JSON.parse(bodyText) : {};
  return {
    id: json.id,
    documentId,
    lineType: json.lineType,
    quantity: json.quantity,
    unitPrice: json.unitPrice,
    raw: json,
  };
}
