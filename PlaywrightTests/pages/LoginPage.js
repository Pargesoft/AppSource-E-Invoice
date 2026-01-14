// PlaywrightTests/pages/LoginPage.js
import BasePage from "./BasePage.js";
import { generateTOTP } from "../utils/totp.js";
import { expect } from "@playwright/test";

export default class LoginPage extends BasePage {
  constructor(page) {
    super(page);
    this.page = page;

    // ✅ Keep your flow, but make locators more resilient
    // If your placeholders really are "someone@example.com" and "Password", these will still match.
    // If they change, name-based fallbacks will save you.
    this.usernameInput = page
      .getByPlaceholder("someone@example.com")
      .or(page.locator('input[name="loginfmt"], input[type="email"]'));

    this.passwordInput = page
      .getByPlaceholder("Password")
      .or(page.locator('input[name="passwd"], input[type="password"]'));

    // "Next / Sign in / Yes" often share the same button in MS login (#idSIButton9)
    this.nextOrPrimaryButton = page
      .getByRole("button", { name: "Next" })
      .or(page.locator("#idSIButton9"));

    this.signInOrPrimaryButton = page
      .getByRole("button", { name: "Sign in" })
      .or(page.locator("#idSIButton9"));

    this.authenticatorAppLink = page.getByRole("link", {
      name: /I can't use my Microsoft Authenticator app right now/i,
    });


    this.useVerificationCodeButton = page.getByRole("button", {
      name: /Use a verification code/i,
    });


    this.otpInput = page
      .getByPlaceholder("Code")
      .or(page.locator('input[name="otc"], input[type="tel"]'));

    this.verifyButton = page
      .getByRole("button", { name: "Verify" })
      .or(page.locator("#idSIButton9"));

    this.approveButton = page.getByRole("button", {
      name: "Approve a request on my Microsoft Authenticator app",
    });

    this.rememberMeYesButton = page
      .getByRole("button", { name: "Yes" })
      .or(page.locator("#idSIButton9"));

    this.useAnotherAccountButton = page.getByRole("button", { name: /Use another account/i });
    this.pickAnAccountText = page.getByText(/Pick an account/i);
  }

  async navigateToLogin(url) {
    // ✅ Avoid networkidle for MS auth redirects (can hang). domcontentloaded is safer.
    await this.page.goto(url, { waitUntil: "domcontentloaded" });

    // Wait until we see either username or pick-account
    await Promise.race([
      this.usernameInput.first().waitFor({ state: "visible", timeout: 60_000 }),
      this.useAnotherAccountButton.waitFor({ state: "visible", timeout: 60_000 }),
      this.pickAnAccountText.waitFor({ state: "visible", timeout: 60_000 }),
    ]).catch(() => {});
  }

  async enterUsername(username) {
    // ✅ If "Pick an account" shows, choose "Use another account" to reach username field
    if (await this.useAnotherAccountButton.isVisible().catch(() => false)) {
      await this.useAnotherAccountButton.click();
    }

    // Some orgs show account tile — click it if it matches
    const tile = this.page.getByRole("button", { name: new RegExp(username, "i") });
    if (await tile.isVisible().catch(() => false)) {
      await tile.click();
      return;
    }

    await expect(this.usernameInput.first()).toBeVisible({ timeout: 60_000 });
    await this.usernameInput.first().fill(username);

    await expect(this.nextOrPrimaryButton.first()).toBeVisible({ timeout: 60_000 });
    await this.nextOrPrimaryButton.first().click();
  }

  async enterPassword(password) {
    await expect(this.passwordInput.first()).toBeVisible({ timeout: 60_000 });
    await this.passwordInput.first().fill(password);

    await expect(this.signInOrPrimaryButton.first()).toBeVisible({ timeout: 60_000 });
    await this.signInOrPrimaryButton.first().click();

    // ✅ Keep your Verify/Approve logic (works for your tenant)
    try {
      await this.verifyButton.first().waitFor({ state: "visible", timeout: 15_000 });
      console.log("✔ Verify appeared — clicking it.");
      await this.verifyButton.first().click({ timeout: 15_000 });
    } catch {
      console.log("ℹ Verify did not appear. Continuing...");
    }

    try {
      await this.approveButton.waitFor({ state: "visible", timeout: 15_000 });
      console.log("✔ Approve appeared — clicking it.");
      await this.approveButton.click({ timeout: 15_000 });
    } catch {
      console.log("ℹ Approve did not appear. Continuing...");
    }
  }

async enterTOTP(secret) {
  const token = generateTOTP(secret);

  // 0) Eğer kod input'u zaten varsa, direkt yaz
  if (await this.otpInput.isVisible().catch(() => false)) {
    await this.otpInput.fill(token);
    await this.verifyButton.click();
    await this.#clickYesIfPresent();
    return;
  }

  // 1) "Sign-in options" yolu (çoğu tenant'ta bu var)
  const signInOptions = this.page.getByRole("link", { name: /Sign-in options/i })
    .or(this.page.getByRole("button", { name: /Sign-in options/i }))
    .or(this.page.getByText(/Sign-in options/i));

  if (await signInOptions.isVisible().catch(() => false)) {
    await signInOptions.click();

    const useVerificationCodeOption = this.page.getByRole("button", { name: /Use a verification code/i })
      .or(this.page.getByRole("link", { name: /Use a verification code/i }))
      .or(this.page.getByText(/Use a verification code/i));

    if (await useVerificationCodeOption.isVisible().catch(() => false)) {
      await useVerificationCodeOption.click();
    }
  }

  // 2) Senin eski akışındaki link: varsa tıkla ama zorunlu değil
  if (await this.authenticatorAppLink.isVisible().catch(() => false)) {
    // overlay ihtimaline karşı force click
    await this.authenticatorAppLink.click({ force: true }).catch(async () => {
      // bazen link viewport dışında kalır
      await this.authenticatorAppLink.scrollIntoViewIfNeeded().catch(() => {});
      await this.authenticatorAppLink.click({ force: true }).catch(() => {});
    });
  }

  // 3) "Use a verification code" butonu varsa tıkla
  if (await this.useVerificationCodeButton.isVisible().catch(() => false)) {
    await this.useVerificationCodeButton.click({ force: true }).catch(() => {});
  }

  // 4) Artık kod input'u gelmeli
  if (!(await this.otpInput.isVisible().catch(() => false))) {
    await this.page.screenshot({ path: "mfa-no-code-input.png", fullPage: true }).catch(() => {});
    throw new Error(
      "TOTP ekranında 'Code' input görünmedi. Tenant push/number matching kullanıyor olabilir. 'mfa-no-code-input.png' kontrol et."
    );
  }

  await this.otpInput.fill(token);
  await this.verifyButton.click();
  await this.#clickYesIfPresent();
}

async #clickYesIfPresent() {
  if (await this.rememberMeButton.isVisible().catch(() => false)) {
    await this.rememberMeButton.click().catch(() => {});
  }
}
}
