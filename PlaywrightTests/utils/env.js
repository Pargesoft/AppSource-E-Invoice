// PlaywrightTests/utils/env.js
import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.resolve(__dirname, "../.env") });
if (!process.env.BC_BASE_URL) {
  dotenv.config({ path: path.resolve(__dirname, "../..", ".env") });
}

function requireEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(
      `Env değişkeni eksik: ${name}. Lokal için .env, CI için Actions secrets/env kontrol edin.`
    );
  }
  return value;
}

// UI
export const BC_BASE_URL = requireEnv("BC_BASE_URL");
export const BC_USERNAME = requireEnv("BC_USERNAME");
export const BC_PASSWORD = requireEnv("BC_PASSWORD");
export const TOTP_SECRET = requireEnv("TOTP_SECRET");

// UI side company/env data (senin dosyada vardı)
export const BC_COMPANY_ID = requireEnv("BC_COMPANY_ID");
export const BC_ENVIRONMENT = requireEnv("BC_ENVIRONMENT");

// API creds (hybrid testlerde gerekli olacak)
export const BC_TENANT_ID = process.env.BC_TENANT_ID || null;
export const BC_CLIENT_ID = process.env.BC_CLIENT_ID || null;
export const BC_CLIENT_SECRET = process.env.BC_CLIENT_SECRET || null;

// Optional overrides
export const BC_API_VERSION = process.env.BC_API_VERSION || "v1.0"; // Postman collection v1.0
export const STORAGE_STATE = process.env.storageState || "storageState.json";

// Build standard BC API base URL
export function getBcApiBaseUrl() {
  if (!BC_TENANT_ID) throw new Error("BC_TENANT_ID missing for API usage.");
  if (!BC_ENVIRONMENT) throw new Error("BC_ENVIRONMENT missing for API usage.");

  // https://api.businesscentral.dynamics.com/v2.0/<tenant>/<environment>/api/v1.0
  return `https://api.businesscentral.dynamics.com/v2.0/${BC_TENANT_ID}/${BC_ENVIRONMENT}/api/${BC_API_VERSION}`;
}
