import { test, expect } from "@playwright/test";
import { createSalesOrder } from "../../utils/bc/api/salesOrder.api.js";

test.describe("@api Sales Order CREATE", () => {
  test("Create Sales Order via API", async ({ request }) => {
    test.setTimeout(2 * 60 * 1000);

    // Ortamında gerçekten var olan müşteri
    const customerNumber =
      process.env.BC_TEST_CUSTOMER_NO || "120.01.001.0002";

    const so = await createSalesOrder(request, { customerNumber });

    // Assert
    expect(so.id, "Sales Order id boş").toBeTruthy();
    expect(so.number, "Sales Order number boş").toBeTruthy();

    console.log("✅ Sales Order CREATED");
    console.log("   Number:", so.number);
    console.log("   Id    :", so.id);

    // ❗ Cleanup YOK
    // Bu test SADECE create'i doğrular
  });
});
