// utils/get-token.js
import { BC_TENANT_ID, BC_CLIENT_ID, BC_CLIENT_SECRET } from "../tests/utils/env.js";

export async function getAccessToken(request) {
  const url = `https://login.microsoftonline.com/${BC_TENANT_ID}/oauth2/v2.0/token`;

  const response = await request.post(url, {
    form: {
      grant_type: "client_credentials",
      client_id: BC_CLIENT_ID,
      client_secret: BC_CLIENT_SECRET,
      scope: "https://api.businesscentral.dynamics.com/.default"
    }
  });

  if (!response.ok()) {
    throw new Error(`❌ Token alınamadı: ${response.status()}`);
  }

  return (await response.json()).access_token;
}
