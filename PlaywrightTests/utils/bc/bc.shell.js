// PlaywrightTests/utils/bc/bc.shell.js
import { expect } from "@playwright/test";
import { expectBCReady } from "./bc.frame.js";

export async function openEFaturaSetupMenu(frame) {
  await expectBCReady(frame);

  // Sol menüden E-Fatura modülü
  await expect(frame.getByRole("menuitem", { name: /Pargesoft E-Fatura/i }))
    .toBeVisible({ timeout: 60_000 });

  await frame.getByRole("menuitem", { name: /Pargesoft E-Fatura/i }).click();

  // Kurulum
  await expect(frame.getByRole("menuitem", { name: /Kurulum/i }))
    .toBeVisible({ timeout: 30_000 });

  await frame.getByRole("menuitem", { name: /Kurulum/i }).click();
}

export async function openMenuItem(frame, nameRegex) {
  await expect(frame.getByRole("menuitem", { name: nameRegex }))
    .toBeVisible({ timeout: 30_000 });

  await frame.getByRole("menuitem", { name: nameRegex }).click();

  await expect(frame.locator('[id^="page-caption"]').first())
    .toBeVisible({ timeout: 60_000 });
}
