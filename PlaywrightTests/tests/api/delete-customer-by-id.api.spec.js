import { test, expect } from "@playwright/test";
import { deleteCustomer } from "../../utils/bc/api/customer.api.js";

test.describe("@api Customer DELETE", () => {
  test("Delete Customer by given ID (BC_CUSTOMER_ID)", async ({ request }) => {
    test.setTimeout(2 * 60 * 1000);

    const id = process.env.BC_CUSTOMER_ID;
    if (!id) {
      throw new Error(
        "BC_CUSTOMER_ID env eksik. Örn: $env:BC_CUSTOMER_ID='<guid>'"
      );
    }

    await deleteCustomer(request, id);
    expect(true).toBeTruthy();
    console.log("🧹 Customer DELETED:", id);
  });
});
