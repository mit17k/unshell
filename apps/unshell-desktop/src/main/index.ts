import { app, BrowserWindow, shell } from "electron";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { registerTerminalIpc } from "./terminal.js";

const here = dirname(fileURLToPath(import.meta.url));
const rendererUrl =
  import.meta.env.DEV && process.env.ELECTRON_RENDERER_URL
    ? new URL(process.env.ELECTRON_RENDERER_URL).href
    : pathToFileURL(join(here, "../renderer/index.html")).href;

function createWindow() {
  const window = new BrowserWindow({
    width: 1280,
    height: 860,
    title: "Unshell",
    backgroundColor: "#16161e",
    webPreferences: {
      preload: join(here, "../preload/index.cjs"),
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true,
    },
  });

  // Links (for example from the terminal) open in the user's browser, never
  // inside the app window.
  window.webContents.setWindowOpenHandler(({ url }) => {
    if (/^https?:\/\//.test(url)) void shell.openExternal(url);
    return { action: "deny" };
  });
  window.webContents.on("will-navigate", (event) => event.preventDefault());

  registerTerminalIpc(window.webContents, rendererUrl);
  void window.loadURL(rendererUrl);
}

void app.whenReady().then(() => {
  createWindow();
  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});
