import BasePage from './BasePage';
import { generateTOTP } from '../utils/totp';

class LoginPage extends BasePage {
    constructor(page) {
        super(page); // Inherit from BasePage
        this.page = page;
        // Locators for elements on the login screen
        this.usernameInput = page.getByPlaceholder('someone@example.com');
        this.passwordInput = page.getByPlaceholder('Password');
        this.nextButton = page.getByRole('button', { name: 'Next' });
        this.signInButton = page.getByRole('button', { name: 'Sign in' });
        this.authenticatorAppLink = page.getByRole('link', { name: "I can't use my Microsoft Authenticator app right now" });
        this.useVerificationCodeButton = page.getByRole('button', { name: 'Use a verification code' });
        this.otpInput = page.getByPlaceholder('Code');
        this.verifyButton = page.getByRole('button', { name: 'Verify' });
        this.rememberMeButton = page.getByRole('button', { name: 'Yes' });
    }

    // Navigate to the login page
    async navigateToLogin(baseURL) {
        await this.page.goto(baseURL, { waitUntil: 'networkidle' });
    }

    // Enter the username
    async enterUsername(username) {
        await this.usernameInput.click();
        await this.usernameInput.fill(username);
        await this.nextButton.click();
    }

    // Enter the password
    async enterPassword(password) {
        await this.passwordInput.click();
        await this.passwordInput.fill(password);
        await this.signInButton.click();
    }

    // Enter the TOTP verification code
    async enterTOTP(secret) {
        const token = generateTOTP(secret); // Use the TOTP utility function
        

        await this.authenticatorAppLink.click();
        await this.useVerificationCodeButton.click();
        await this.otpInput.click();
        await this.otpInput.fill(token);
        await this.verifyButton.click();
        await this.rememberMeButton.click();
    }
}

export default LoginPage;
