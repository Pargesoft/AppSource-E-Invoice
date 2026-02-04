// PlaywrightTests/utils/bc/salesOrder.api.js
import { expect } from "@playwright/test";
import { getAccessToken } from "../../get-token.js";
import { BC_COMPANY_ID, BC_ENVIRONMENT, BC_TENANT_ID } from "../../env.js";

function requireApiEnv() {
  // env.js'ye göre BC_COMPANY_ID ve BC_ENVIRONMENT zorunlu:contentReference[oaicite:3]{index=3}
  if (!BC_TENANT_ID) throw new Error("Env eksik: BC_TENANT_ID (API için gerekli)");
  if (!BC_ENVIRONMENT) throw new Error("Env eksik: BC_ENVIRONMENT");
  if (!BC_COMPANY_ID) throw new Error("Env eksik: BC_COMPANY_ID");
}

function buildApiBaseUrl() {
  requireApiEnv();
  // Standard BC API root: https://api.businesscentral.dynamics.com/v2.0/{tenant}/{environment}/api/v2.0
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

// POST {{baseUrl}}/companies({{company_id}})/salesOrders  (Postman'da var):contentReference[oaicite:4]{index=4}
export async function createSalesOrder(request, { customerNumber, externalDocumentNumber } = {}) {
  if (!customerNumber) throw new Error("createSalesOrder: customerNumber zorunlu.");

  const baseUrl = buildApiBaseUrl();
  const headers = await authHeaders(request);

  const url = `${baseUrl}/companies(${BC_COMPANY_ID})/salesOrders`;
  const payload = {
    customerNumber,
    externalDocumentNumber: externalDocumentNumber ?? `PW-${Date.now()}`,
  };

  const res = await request.post(url, { headers, data: payload });
  const bodyText = await res.text().catch(() => "");

  expect(res.ok(), `Create Sales Order failed: ${res.status()} ${bodyText}`).toBeTruthy();

  const json = bodyText ? JSON.parse(bodyText) : {};
  return { id: json.id, number: json.number, raw: json };
}

// DELETE {{baseUrl}}/companies({{company_id}})/salesOrders({{salesOrder_id}}):contentReference[oaicite:5]{index=5}
export async function deleteSalesOrder(request, salesOrderId) {
  if (!salesOrderId) throw new Error("deleteSalesOrder: salesOrderId zorunlu.");

  const baseUrl = buildApiBaseUrl();
  const headers = await authHeaders(request);

  const url = `${baseUrl}/companies(${BC_COMPANY_ID})/salesOrders(${salesOrderId})`;

  // BC delete bazen ETag ister; If-Match: "*" güvenli yaklaşım
  const res = await request.delete(url, { headers: { ...headers, "If-Match": "*" } });

  // Postman response 204 No Content gösteriyor:contentReference[oaicite:6]{index=6}
  if (!(res.status() === 204 || res.status() === 200)) {
    const body = await res.text().catch(() => "");
    throw new Error(`Delete Sales Order failed: ${res.status()} ${body}`);
  }
}
