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
 * GET Item by Number
 * GET /companies({companyId})/items?$filter=number eq 'xxx'
 */
export async function getItemByNumber(request, itemNo) {
  if (!itemNo) throw new Error("getItemByNumber: itemNo zorunlu");

  const baseUrl = buildApiBaseUrl();
  const headers = await authHeaders(request);

  const url =
    `${baseUrl}/companies(${BC_COMPANY_ID})/items` +
    `?$filter=number eq '${String(itemNo).replace(/'/g, "''")}'`;

  const res = await request.get(url, { headers });
  const bodyText = await res.text().catch(() => "");

  expect(res.ok(), `Get Item failed: ${res.status()} ${bodyText}`).toBeTruthy();

  const json = bodyText ? JSON.parse(bodyText) : {};
  const item = json?.value?.[0];

  if (!item?.id) {
    throw new Error(`Item bulunamadı: number=${itemNo}`);
  }

  return {
    id: item.id,
    number: item.number,
    displayName: item.displayName,
    raw: item,
  };
}
