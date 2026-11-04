import type { Capabilities, Health } from "@unshell/contracts";

export type Overview =
  | {
      connected: true;
      endpoint: string;
      health: Health;
      capabilities: Capabilities;
    }
  | { connected: false; endpoint: string; error: string };

export interface DesktopBridge {
  overview(): Promise<Overview>;
}
