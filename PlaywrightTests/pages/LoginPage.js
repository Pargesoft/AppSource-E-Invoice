// pages/LoginPage.js
import BasePage from "./BasePage.js";
import { generateTOTP } from "../utils/totp.js";

export default class LoginPage extends BasePage {
  constructor(page) {
    super(page);
    this.page = page;

    this.usernameInput = page.getByPlaceholder("someone@example.com");
    this.passwordInput = page.getByPlaceholder("Password");
    this.nextButton = page.getByRole("button", { name: "Next" });
    this.signInButton = page.getByRole("button", { name: "Sign in" });
    this.authenticatorAppLink = page.getByRole("link", {
      name: "I can't use my Microsoft Authenticator app right now"
    });
    this.useVerificationCodeButton = page.getByRole("button", {
      name: "Use a verification code"
    });
    this.otpInput = page.getByPlaceholder("Code");
    this.verifyButton = page.getByRole("button", { name: "Verify" });
    this.rememberMeButton = page.getByRole("button", { name: "Yes" });
  }

  async navigateToLogin(url) {
    await this.page.goto(url, { waitUntil: "networkidle" });
  }

  async enterUsername(username) {
    await this.usernameInput.fill(username);
    await this.nextButton.click();
  }

  async enterPassword(password) {
    await this.passwordInput.fill(password);
    await this.signInButton.click();

  
    if (await this.verifyButton.isVisible().catch(() => false)) {
      console.log("✔ Verify button appeared after password — clicking it.");
      await this.verifyButton.click();

      // Approve request butonunu ara
      const approveButton = this.page.getByRole("button", { 
        name: "Approve a request on my Microsoft Authenticator app" 
      });

      if (await approveButton.isVisible().catch(() => false)) {
        console.log("✔ Approve request button appeared — clicking it.");
        await approveButton.click();
      }

    }
 
  }

  async enterTOTP(secret) {
    const token = generateTOTP(secret);

    await this.authenticatorAppLink.click();
    await this.useVerificationCodeButton.click();
    await this.otpInput.fill(token);
    await this.verifyButton.click();
    await this.rememberMeButton.click();
  }
}
