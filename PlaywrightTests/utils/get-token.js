// PlaywrightTests/utils/get-token.js
import { BC_TENANT_ID, BC_CLIENT_ID, BC_CLIENT_SECRET } from "./env.js";

export async function getAccessToken(request) {
  if (!BC_TENANT_ID || !BC_CLIENT_ID || !BC_CLIENT_SECRET) {
    throw new Error(
      "API için env eksik: BC_TENANT_ID / BC_CLIENT_ID / BC_CLIENT_SECRET. .env / GitHub Secrets kontrol edin."
    );
  }

  const url = `https://login.microsoftonline.com/${BC_TENANT_ID}/oauth2/v2.0/token`;

  const response = await request.post(url, {
    form: {
      grant_type: "client_credentials",
      client_id: BC_CLIENT_ID,
      client_secret: BC_CLIENT_SECRET,
      scope: "https://api.businesscentral.dynamics.com/.default",
    },
  });

  if (!response.ok()) {
    const body = await response.text().catch(() => "");
    throw new Error(`❌ Token alınamadı: ${response.status()} ${body}`);
  }

  return (await response.json()).access_token;
}
