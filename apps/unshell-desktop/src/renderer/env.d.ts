import type { UnshellBridge } from "../shared/terminal.js";

declare global {
  interface Window {
    /** Present inside Electron; missing in a plain browser. */
    unshell?: UnshellBridge;
  }
}
