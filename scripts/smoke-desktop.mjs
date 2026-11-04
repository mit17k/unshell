import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { resolve } from "node:path";
import { _electron as electron } from "playwright";
import { buildApp } from "../apps/unshell-api/src/app.ts";

const api = buildApp();
const endpoint = await api.listen({ host: "127.0.0.1", port: 0 });
const desktopPath = resolve("apps/unshell-desktop");
const require = createRequire(`${desktopPath}/package.json`);
const env = { ...process.env, UNSHELL_API_URL: endpoint };
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
  await page.getByText("Connected", { exact: true }).waitFor();
  assert.equal(await page.locator(".capability").count(), 5);
  assert.equal(
    await page.getByRole("button", { name: "Design language" }).count(),
    0,
  );
  assert.deepEqual(
    await page.evaluate(() => ({
      node: typeof globalThis.require,
      bridge: Object.keys(globalThis.unshell),
    })),
    { node: "undefined", bridge: ["overview"] },
  );
  const preferences = await desktop.evaluate(({ BrowserWindow }) => {
    const window = BrowserWindow.getAllWindows()[0];
    return window.webContents.getLastWebPreferences();
  });
  assert.equal(preferences.sandbox, true);
  assert.equal(preferences.contextIsolation, true);
  assert.equal(preferences.nodeIntegration, false);
  assert.equal(
    await desktop.evaluate(({ BrowserWindow }) => {
      const contents = BrowserWindow.getAllWindows()[0].webContents;
      contents.openDevTools();
      return contents.isDevToolsOpened();
    }),
    false,
  );
  await page.screenshot({
    path: "apps/unshell-desktop/out/smoke.png",
    fullPage: true,
  });
  await api.close();
  await page.getByRole("button", { name: "Refresh connection" }).click();
  await page.getByText("Disconnected", { exact: true }).waitFor();
  assert.deepEqual(errors, []);
  console.log(
    "Desktop smoke passed: API connection, capabilities, isolated bridge, release UI, and disconnection.",
  );
} finally {
  if (desktop) await desktop.close();
  await api.close();
}
