// PlaywrightTests/utils/env.js
import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";

// __dirname hesapla (ESM olduğu için klasik __dirname yok)
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 1) Önce PlaywrightTests/.env dosyasını dene
dotenv.config({ path: path.resolve(__dirname, "../.env") });

// 2) Hâlâ BC_BASE_URL yoksa, root (.env) dosyasını da dene (C:\AppSource-E-Invoice\.env)
if (!process.env.BC_BASE_URL) {
  dotenv.config({ path: path.resolve(__dirname, "../..", ".env") });
}

function requireEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(
      `Env değişkeni eksik: ${name}. Lokal için .env dosyasını, CI için GitHub Actions env ayarlarını kontrol edin.`
    );
  }
  return value;
}

// UI ve genel testler için zorunlu değişkenler
export const BC_BASE_URL = requireEnv("BC_BASE_URL");
export const BC_USERNAME = requireEnv("BC_USERNAME");
export const BC_PASSWORD = requireEnv("BC_PASSWORD");
export const TOTP_SECRET = requireEnv("TOTP_SECRET");
export const BC_COMPANY_ID = requireEnv("BC_COMPANY_ID");
export const BC_ENVIRONMENT = requireEnv("BC_ENVIRONMENT");

// API için kullanılacak, ama şu an zorunlu olmayanlar
export const BC_TENANT_ID = process.env.BC_TENANT_ID || null;
export const BC_CLIENT_ID = process.env.BC_CLIENT_ID || null;
export const BC_CLIENT_SECRET = process.env.BC_CLIENT_SECRET || null;
export const BC_AUTH_URL = process.env.BC_AUTH_URL || null;
export const BC_REFRESH_TOKEN = process.env.BC_REFRESH_TOKEN || null;

export const IS_REFRESH_COOKIES =
  (process.env.isRefreshCookies ?? "0") === "1";

export const STORAGE_STATE = process.env.storageState || "storageState.json";
