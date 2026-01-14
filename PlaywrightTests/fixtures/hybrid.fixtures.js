// PlaywrightTests/fixtures/hybrid.fixtures.js
import { test as base, expect } from "@playwright/test";
import { BC_BASE_URL, BC_TENANT_ID, BC_CLIENT_ID, BC_CLIENT_SECRET, BC_COMPANY_ID, getBcApiBaseUrl } from "../utils/env.js";
import { getBCFrame } from "../utils/bc/bc.frame.js";
import { getAccessTokenClientCredentials } from "../utils/api/apiAuth.js";
import { BcApiClient } from "../utils/api/bcApiClient.js";

export const test = base.extend({
  frame: async ({ page }, use) => {
    await page.goto(BC_BASE_URL, { waitUntil: "domcontentloaded" });
    await use(getBCFrame(page));
  },

  bcApi: async ({}, use) => {
    if (!BC_TENANT_ID || !BC_CLIENT_ID || !BC_CLIENT_SECRET) {
      throw new Error("Hybrid tests require BC_TENANT_ID, BC_CLIENT_ID, BC_CLIENT_SECRET in .env");
    }

    const token = await getAccessTokenClientCredentials({
      tenantId: BC_TENANT_ID,
      clientId: BC_CLIENT_ID,
      clientSecret: BC_CLIENT_SECRET,
    });

    const bcApi = new BcApiClient({
      baseUrl: getBcApiBaseUrl(),
      accessToken: token,
      companyId: BC_COMPANY_ID,
    });

    await bcApi.init();
    await use(bcApi);
    await bcApi.dispose();
  },
});

export { expect };
