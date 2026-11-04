import { contextBridge, ipcRenderer } from "electron";
import type { DesktopBridge, Overview } from "../bridge.js";

const bridge: DesktopBridge = {
  overview: (): Promise<Overview> => ipcRenderer.invoke("unshell:overview"),
};
contextBridge.exposeInMainWorld("unshell", bridge);
