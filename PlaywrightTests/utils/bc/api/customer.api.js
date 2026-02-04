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
 * CREATE Customer
 * POST /companies({companyId})/customers
 *
 * ⚠️ BC Standard API sadece FLAT alan kabul eder
 */
export async function createCustomer(
  request,
  {
    number,
    displayName,
    phoneNumber,
    email,
  } = {}
) {
  if (!number) throw new Error("createCustomer: number zorunlu");
  if (!displayName) throw new Error("createCustomer: displayName zorunlu");

  const baseUrl = buildApiBaseUrl();
  const headers = await authHeaders(request);

  const payload = {
    number,
    displayName,
  };

  // Optional alanlar
  if (phoneNumber) payload.phoneNumber = phoneNumber;
  if (email) payload.email = email;

  const res = await request.post(
    `${baseUrl}/companies(${BC_COMPANY_ID})/customers`,
    { headers, data: payload }
  );

  const bodyText = await res.text().catch(() => "");

  if (res.status() === 403) {
    throw new Error(
      `BC API 403 Permission. Customer create için permission set eksik olabilir. Body: ${bodyText}`
    );
  }

  expect(
    res.ok(),
    `Create Customer failed: ${res.status()} ${bodyText}`
  ).toBeTruthy();

  const json = bodyText ? JSON.parse(bodyText) : {};
  return {
    id: json.id,
    number: json.number,
    displayName: json.displayName,
    raw: json,
  };
}

/**
 * DELETE Customer
 * DELETE /companies({companyId})/customers({customerId})
 */
export async function deleteCustomer(request, customerId) {
  if (!customerId) throw new Error("deleteCustomer: customerId zorunlu");

  const baseUrl = buildApiBaseUrl();
  const headers = await authHeaders(request);

  const res = await request.delete(
    `${baseUrl}/companies(${BC_COMPANY_ID})/customers(${customerId})`,
    {
      headers: {
        ...headers,
        "If-Match": "*",
      },
    }
  );

  if (!(res.status() === 204 || res.status() === 200)) {
    const body = await res.text().catch(() => "");
    throw new Error(`Delete Customer failed: ${res.status()} ${body}`);
  }
}

/**
 * Helper: create → callback → always delete
 */
export async function withCustomer(request, customerData, callback) {
  const customer = await createCustomer(request, customerData);
  try {
    return await callback(customer);
  } finally {
    await deleteCustomer(request, customer.id);
  }
}
// PlaywrightTests/utils/bc/customer.api.js

export async function getCustomerByNumber(request, customerNumber) {
  if (!customerNumber) throw new Error("getCustomerByNumber: customerNumber zorunlu");

  // aynı dosyanda zaten olan helper'ları kullanıyoruz:
  const baseUrl = buildApiBaseUrl();
  const headers = await authHeaders(request);

  // OData: tek tırnak escape
  const safe = String(customerNumber).replace(/'/g, "''");

  // NOT: encodeURIComponent içinde tek tırnak vs bozmasın diye filter stringini sade kuruyoruz
  const url = `${baseUrl}/companies(${BC_COMPANY_ID})/customers?$filter=number eq '${safe}'&$top=1`;

  const res = await request.get(url, { headers });
  const bodyText = await res.text().catch(() => "");

  expect(res.ok(), `Get Customer failed: ${res.status()} ${bodyText}`).toBeTruthy();

  const json = bodyText ? JSON.parse(bodyText) : {};
  const row = Array.isArray(json.value) ? json.value[0] : null;

  if (!row) throw new Error(`Customer bulunamadı. number=${customerNumber}`);

  return { id: row.id, number: row.number, displayName: row.displayName, raw: row };
}

export function getSalesCustomerNoFromEnv() {
  const no = process.env.BC_SALES_CUSTOMER_NO;
  if (!no) {
    throw new Error(
      "Env eksik: BC_SALES_CUSTOMER_NO. Posting setup'ı hazır bir customer no ver."
    );
  }
  return no;
}

