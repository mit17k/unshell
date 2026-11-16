import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { resolve } from "node:path";
import { _electron as electron } from "playwright";

const desktopPath = resolve("apps/unshell-desktop");
const require = createRequire(`${desktopPath}/package.json`);
const env = { ...process.env };
delete env.ELECTRON_RUN_AS_NODE;
let desktop;
try {
  desktop = await electron.launch({
    executablePath:
      process.env.UNSHELL_DESKTOP_EXECUTABLE ?? require("electron"),
    args: process.env.UNSHELL_DESKTOP_EXECUTABLE ? [] : [desktopPath],
    env,
    timeout: 30000,
  });
  const page = await desktop.firstWindow();
  const errors = [];
  page.on("pageerror", (error) => errors.push(error.message));
  await page.waitForLoadState("domcontentloaded");
  assert.equal(await page.title(), "Unshell");
  assert.equal(
    await page.evaluate(() => typeof globalThis.require),
    "undefined",
  );
  const preferences = await desktop.evaluate(({ BrowserWindow }) =>
    BrowserWindow.getAllWindows()[0].webContents.getLastWebPreferences(),
  );
  assert.equal(preferences.sandbox, true);
  assert.equal(preferences.contextIsolation, true);
  assert.equal(preferences.nodeIntegration, false);
  assert.deepEqual(errors, []);
  console.log("Desktop smoke passed: empty sandboxed window opens.");
} finally {
  if (desktop) await desktop.close();
}
