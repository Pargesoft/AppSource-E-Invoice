// PlaywrightTests/utils/api/apiAuth.js
import { request } from "@playwright/test";

export async function getAccessTokenClientCredentials({ tenantId, clientId, clientSecret }) {
  const ctx = await request.newContext();
  const url = `https://login.microsoftonline.com/${tenantId}/oauth2/v2.0/token`;

  const body = new URLSearchParams({
    client_id: clientId,
    client_secret: clientSecret,
    scope: "https://api.businesscentral.dynamics.com/.default",
    grant_type: "client_credentials",
  });

  const r = await ctx.post(url, {
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: body.toString(),
  });

  if (!r.ok()) throw new Error(`Token failed: ${r.status()} ${await r.text()}`);
  const json = await r.json();
  await ctx.dispose();
  return json.access_token;
}
