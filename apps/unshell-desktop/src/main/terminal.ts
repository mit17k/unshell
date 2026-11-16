import { chmodSync, existsSync, statSync } from "node:fs";
import { createRequire } from "node:module";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import {
  ipcMain,
  type IpcMainEvent,
  type IpcMainInvokeEvent,
  type WebContents,
} from "electron";
import type * as NodePty from "node-pty";
import { TerminalChannel } from "../shared/terminal.js";
import { PtyHost } from "./pty-host.js";

// node-pty is a native CommonJS module kept outside the bundle.
const require = createRequire(import.meta.url);
let nodePty: typeof NodePty | undefined;

function loadNodePty() {
  if (nodePty) return nodePty;
  nodePty = require("node-pty") as typeof NodePty;
  // Some installs drop the execute bit from the macOS spawn helper, which makes
  // every spawn fail with "posix_spawnp failed".
  if (process.platform === "darwin") {
    const base = dirname(require.resolve("node-pty/package.json"));
    const helper = join(
      base,
      "prebuilds",
      `darwin-${process.arch}`,
      "spawn-helper",
    );
    const unpacked = helper.replace("app.asar", "app.asar.unpacked");
    for (const path of [helper, unpacked]) {
      try {
        if (existsSync(path) && !(statSync(path).mode & 0o111))
          chmodSync(path, 0o755);
      } catch {
        // Read-only installs keep whatever mode they shipped with.
      }
    }
  }
  return nodePty;
}

function defaultShell() {
  if (process.platform === "win32")
    return process.env.COMSPEC ?? "powershell.exe";
  return (
    process.env.SHELL ??
    (process.platform === "darwin" ? "/bin/zsh" : "/bin/bash")
  );
}

function shellEnv() {
  const env: Record<string, string> = {};
  for (const [key, value] of Object.entries(process.env)) {
    if (value !== undefined && !key.startsWith("ELECTRON_")) env[key] = value;
  }
  return {
    ...env,
    TERM: "xterm-256color",
    COLORTERM: "truecolor",
    TERM_PROGRAM: "Unshell",
  };
}

/**
 * Serves terminals to one window. Every request must come from that window's
 * main frame at the expected renderer URL; anything else is ignored.
 */
export function registerTerminalIpc(
  contents: WebContents,
  rendererUrl: string,
) {
  const trusted = (event: IpcMainEvent | IpcMainInvokeEvent) =>
    event.sender === contents &&
    event.senderFrame === contents.mainFrame &&
    event.senderFrame?.url === rendererUrl;

  const shell = defaultShell();
  const host = new PtyHost({
    shell,
    spawn: (file, { cols, rows }) =>
      loadNodePty().spawn(file, process.platform === "win32" ? [] : ["-l"], {
        name: "xterm-256color",
        cols,
        rows,
        cwd: homedir(),
        env: shellEnv(),
      }),
    send: (event: "data" | "exit", id: number, payload: string | number) => {
      if (contents.isDestroyed()) return;
      contents.send(
        event === "data" ? TerminalChannel.data : TerminalChannel.exit,
        id,
        payload,
      );
    },
  });

  ipcMain.handle(TerminalChannel.create, (event, size: unknown) => {
    if (!trusted(event)) throw new Error("Untrusted frame");
    return host.create(size as never);
  });
  const on = (channel: string, handler: (id: number, value: unknown) => void) =>
    ipcMain.on(channel, (event, id: unknown, value: unknown) => {
      if (trusted(event) && typeof id === "number") handler(id, value);
    });
  on(TerminalChannel.write, (id, data) => host.write(id, data));
  on(TerminalChannel.resize, (id, size) => host.resize(id, size));
  on(TerminalChannel.ack, (id, chars) => host.ack(id, chars));
  on(TerminalChannel.kill, (id) => host.kill(id));

  const cleanup = () => {
    host.dispose();
    ipcMain.removeHandler(TerminalChannel.create);
    for (const channel of [
      TerminalChannel.write,
      TerminalChannel.resize,
      TerminalChannel.ack,
      TerminalChannel.kill,
    ]) {
      ipcMain.removeAllListeners(channel);
    }
  };
  contents.once("destroyed", cleanup);
  // A reload starts a fresh renderer, so its terminals are orphaned.
  contents.on("did-start-navigation", (details) => {
    if (details.isMainFrame && !details.isSameDocument) host.dispose();
  });
}
