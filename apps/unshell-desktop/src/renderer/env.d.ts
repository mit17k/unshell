import type { DesktopBridge } from "../bridge.js";
declare global {
  interface Window {
    unshell: DesktopBridge;
  }
}
