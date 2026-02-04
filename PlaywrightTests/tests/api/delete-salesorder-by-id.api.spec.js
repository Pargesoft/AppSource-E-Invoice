import { test, expect } from "@playwright/test";
import { deleteSalesOrder } from "../../utils/bc/api/salesOrder.api.js";

test.describe("@api Sales Order DELETE", () => {
  test("Delete Sales Order by given ID (BC_SALESORDER_ID)", async ({ request }) => {
    test.setTimeout(2 * 60 * 1000);

    const id = process.env.BC_SALESORDER_ID;
    if (!id) {
      throw new Error(
        "BC_SALESORDER_ID env eksik. Örn: $env:BC_SALESORDER_ID='<guid>'"
      );
    }

    await deleteSalesOrder(request, id);
    expect(true).toBeTruthy();
    console.log("🧹 Deleted Sales Order:", id);
  });
});
