// pages/BasePage.js
export default class BasePage {
  constructor(page) {
    this.page = page;
  }

  async navigateTo(url) {
    await this.page.goto(url, {
      timeout: 50000,
      waitUntil: "domcontentloaded"
    });
  }

  async waitForElementVisibleAndClick(locator, timeout = 60000) {
    await this.waitForElement(locator, timeout);
    await this.page.click(locator);
  }

  async waitForElement(locator, timeout = 60000) {
    await this.page.waitForSelector(locator, { state: "visible", timeout });
  }

  async waitForElementToBeHidden(locator, timeout = 60000) {
    await this.page.waitForSelector(locator, { state: "hidden", timeout });
  }

  async clickElement(locator) {
    await this.waitForElement(locator);
    await this.page.click(locator);
  }

  async typeText(locator, text) {
    await this.waitForElement(locator);
    await this.page.fill(locator, text);
  }

  async isElementVisible(locator, timeout = 5000) {
    try {
      await this.waitForElement(locator, timeout);
      return true;
    } catch {
      return false;
    }
  }

  async getText(locator) {
    await this.waitForElement(locator);
    return this.page.textContent(locator);
  }

  async getAttribute(locator, attr) {
    await this.waitForElement(locator);
    return this.page.getAttribute(locator, attr);
  }

  async selectOption(locator, option) {
    await this.waitForElement(locator);
    await this.page.selectOption(locator, option);
  }

  async hoverElement(locator) {
    await this.waitForElement(locator);
    await this.page.hover(locator);
  }

  async pressKey(key) {
    await this.page.keyboard.press(key);
  }

  async waitForNavigation() {
    await this.page.waitForNavigation();
  }

  async waitForLoadState(state = "load") {
    await this.page.waitForLoadState(state);
  }

  async waitForTimeout(ms) {
    await this.page.waitForTimeout(ms);
  }
}
