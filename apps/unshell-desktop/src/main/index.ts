import { app, BrowserWindow, dialog, ipcMain, Menu, session } from "electron";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { createClient } from "@unshell/sdk";
import type { Overview } from "../bridge.js";

const here = dirname(fileURLToPath(import.meta.url));
let window: BrowserWindow | null = null;

async function start() {
  const client = createClient(process.env.UNSHELL_API_URL);
  const rendererPath = join(here, "../renderer/index.html");
  const rendererUrl = new URL(
    import.meta.env.DEV && process.env.ELECTRON_RENDERER_URL
      ? process.env.ELECTRON_RENDERER_URL
      : pathToFileURL(rendererPath).href,
  ).href;

  session.defaultSession.setPermissionRequestHandler(
    (_contents, _permission, callback) => callback(false),
  );
  session.defaultSession.setPermissionCheckHandler(() => false);

  ipcMain.handle("unshell:overview", async (event): Promise<Overview> => {
    if (
      !window ||
      event.sender !== window.webContents ||
      event.senderFrame !== window.webContents.mainFrame ||
      event.senderFrame.url !== rendererUrl
    ) {
      throw new Error("Untrusted desktop frame");
    }
    try {
      const [health, capabilities] = await Promise.all([
        client.health(),
        client.capabilities(),
      ]);
      return {
        connected: true,
        endpoint: client.baseUrl,
        health,
        capabilities,
      };
    } catch (error) {
      return {
        connected: false,
        endpoint: client.baseUrl,
        error: error instanceof Error ? error.message : "API unavailable",
      };
    }
  });

  function createWindow() {
    window = new BrowserWindow({
      width: 1280,
      height: 860,
      minWidth: 880,
      minHeight: 640,
      title: "Unshell",
      show: false,
      webPreferences: {
        preload: join(here, "../preload/index.cjs"),
        nodeIntegration: false,
        contextIsolation: true,
        sandbox: true,
        devTools: import.meta.env.DEV,
      },
    });
    window.webContents.setWindowOpenHandler(() => ({ action: "deny" }));
    window.webContents.on("will-navigate", (event) => event.preventDefault());
    window.webContents.on("will-attach-webview", (event) =>
      event.preventDefault(),
    );
    window.once("ready-to-show", () => window?.show());
    window.on("closed", () => {
      window = null;
    });
    void window.loadURL(rendererUrl).catch((error: unknown) => {
      dialog.showErrorBox("Unable to open Unshell", String(error));
      app.quit();
    });
  }
  if (!import.meta.env.DEV) Menu.setApplicationMenu(null);
  createWindow();
  app.on("activate", () => {
    if (!window) createWindow();
  });
}

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});
void app
  .whenReady()
  .then(start)
  .catch((error: unknown) => {
    dialog.showErrorBox(
      "Unshell could not start",
      error instanceof Error ? error.message : String(error),
    );
    app.quit();
  });
