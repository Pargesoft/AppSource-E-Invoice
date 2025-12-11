// utils/totp.js
import { TOTP } from "otpauth";

export function generateTOTP(secret) {
  const totp = new TOTP({
    algorithm: "SHA1",
    digits: 6,
    period: 30,
    secret
  });

  return totp.generate();
}
