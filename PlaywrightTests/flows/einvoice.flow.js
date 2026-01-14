// PlaywrightTests/flows/einvoice.flow.js
import { openEFaturaSetupMenu, openMenuItem } from "../utils/bc/bc.shell.js";
import { getGrid, resetGridToTop, findRowByContainsAll } from "../utils/bc/bc.grid.js";
import { expect } from "@playwright/test";

export async function openCodeMappingPage(frame) {
  await openEFaturaSetupMenu(frame);
  await openMenuItem(frame, /E-Fatura Kod Eşleme/i);
}

export async function openTaxCodesPage(frame) {
  await openEFaturaSetupMenu(frame);
  await openMenuItem(frame, /E-Fatura Vergi Türü Kodu/i);
}

export async function openOutgoingQueue(frame) {
  // Menü path tenant'a göre değişebiliyor; “Tell me” yoksa burayı kendi menüne göre ayarla.
  await frame.getByRole("menuitem", { name: /Pargesoft E-Fatura/i }).click();
  await openMenuItem(frame, /Outgoing Queue|Giden Kuyruk|Outgoing/i);
}

export async function openLiableCompanies(frame) {
  await openEFaturaSetupMenu(frame);
  await openMenuItem(frame, /Liable Companies|Sorumlu Şirket/i);
}

export async function openEExportSetup(frame) {
  await openEFaturaSetupMenu(frame);
  await openMenuItem(frame, /E-İhracat Setup|E-İhracat Kurulum/i);
}

// Generic “grid row exists” helper
export async function expectRowExists(frame, page, mustContain) {
  const grid = await getGrid(frame);
  await resetGridToTop(page, grid);
  const row = await findRowByContainsAll({ page, grid, mustContain });
  expect(row, `Row not found: ${mustContain.join(" | ")}`).toBeTruthy();
  return row;
}
