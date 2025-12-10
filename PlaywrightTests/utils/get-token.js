import dotenv from 'dotenv';
dotenv.config();

export async function getAccessToken(request) {
  const tenant = process.env.BC_TENANT_ID;
  const clientId = process.env.BC_CLIENT_ID;
  const clientSecret = process.env.BC_CLIENT_SECRET;

  const tokenUrl = `https://login.microsoftonline.com/${tenant}/oauth2/v2.0/token`;

  const response = await request.post(tokenUrl, {
    form: {
      grant_type: 'client_credentials',
      client_id: clientId,
      client_secret: clientSecret,
      scope: "https://api.businesscentral.dynamics.com/.default"
    }
  });

  if (!response.ok()) {
    throw new Error(`Token alınamadı: ${response.status()}`);
  }

  const data = await response.json();
  return data.access_token;
}
