class BasePage {
    constructor(page) {
       this.page = page;
    }

    // Navigates to the specified URL and waits for the DOM content to be fully loaded.
    async navigateTo(url) {
        await this.page.goto(url, { timeout: 50000, waitUntil: 'domcontentloaded' });
    }
    // Waits for the element to be visible and clickable 
    async waitForElementVisibleAndClick(locator, timeout = 60000){
        await this.waitForElement(locator, timeout);
        await this.page.click(locator);
    }

    // Waits for an element to become visible within the specified timeout.
    async waitForElement(locator, timeout = 60000) {
        await this.page.waitForSelector(locator, { state: 'visible', timeout });
    }

    // Waits for an element to become hidden within the specified timeout.
    async waitForElementToBeHidden(locator, timeout = 60000) {
        await this.page.waitForSelector(locator, { state: 'hidden', timeout });
    }

    // Waits for an element to be visible and then clicks it.
    async clickElement(locator) {
        await this.waitForElement(locator);
        await this.page.click(locator);
    }

    // Waits for an element to be visible and types text into it.
    async typeText(locator, text) {
        await this.waitForElement(locator);
        await this.page.fill(locator, text);
    }

    // Checks if an element is visible on the page within the specified timeout.
    async isElementVisible(locator, timeout = 5000) {
        try {
            await this.waitForElement(locator, timeout);
            return true;
        } catch (error) {
            return false;
        }
    }

    // Retrieves the text content of an element after ensuring it is visible.
    async getText(locator) {
        await this.waitForElement(locator);
        return await this.page.textContent(locator);
    }

    // Retrieves the value of a specific attribute from an element.
    async getAttribute(locator, attributeName) {
        await this.waitForElement(locator);
        return await this.page.getAttribute(locator, attributeName);
    }

    // Waits for an element to be visible and selects an option from a dropdown.
    async selectOption(locator, option) {
        await this.waitForElement(locator);
        await this.page.selectOption(locator, option);
    }

    // Waits for an element to be visible and hovers over it.
    async hoverElement(locator) {
        await this.waitForElement(locator);
        await this.page.hover(locator);
    }

    // Simulates a key press on the keyboard.
    async pressKey(key) {
        await this.page.keyboard.press(key);
    }

    // Waits for a page navigation to complete.
    async waitForNavigation() {
        await this.page.waitForNavigation();
    }

    // Counts the number of elements matching the given locator.
    async getElementCount(locator) {
        return await this.page.locator(locator).count();
    }

    // Scrolls to the specified element to bring it into view.
    async scrollToElement(locator) {
        const element = await this.page.$(locator);
        await element.scrollIntoViewIfNeeded();
    }

    // Takes a screenshot of the current page and saves it to the specified path.
    async takeScreenshot(path) {
        await this.page.screenshot({ path: path });
    }

    // Waits for the page's load state to reach the specified state.
    async waitForLoadState(state = 'load') {
        await this.page.waitForLoadState(state);
    }

    // Performs a drag-and-drop action from the source element to the target element.
    async dragAndDrop(sourceLocator, targetLocator) {
        await this.page.dragAndDrop(sourceLocator, targetLocator);
    }

    // Executes a custom script in the browser's context.
    async evaluateScript(script) {
        return await this.page.evaluate(script);
    }

    // Pauses execution for a specified amount of time (in milliseconds).
    async waitForTimeout(timeout) {
        await this.page.waitForTimeout(timeout);
    }
}

module.exports = BasePage;
