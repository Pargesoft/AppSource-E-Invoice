import { test, expect } from "@playwright/test";
import { createCustomer } from "../../utils/bc/api/customer.api.js";

test.describe("@api Customer CREATE", () => {
  test("Create Customer via API", async ({ request }) => {
    test.setTimeout(2 * 60 * 1000);

    const uniqueNo = `C-${Date.now()}`;

    const customer = await createCustomer(request, {
      number: uniqueNo,
      displayName: `PW Customer ${uniqueNo}`,
      phoneNumber: "5550000000",
      email: "test@playwright.local",
    });

    expect(customer.id).toBeTruthy();
    expect(customer.number).toBe(uniqueNo);

    console.log("✅ Customer CREATED");
    console.log("   Number:", customer.number);
    console.log("   Id    :", customer.id);

  
  });
});
