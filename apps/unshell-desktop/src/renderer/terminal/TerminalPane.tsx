import { useEffect, useRef } from "react";
import { Terminal } from "@xterm/xterm";
import { FitAddon } from "@xterm/addon-fit";
import { Unicode11Addon } from "@xterm/addon-unicode11";
import { WebLinksAddon } from "@xterm/addon-web-links";
import { WebglAddon } from "@xterm/addon-webgl";
import type { TerminalInfo } from "../../shared/terminal.js";
import { symbolsFont, terminalFont, tokyoNightTerminal } from "./theme.js";
import "@xterm/xterm/css/xterm.css";
import "./terminal.css";

export interface TerminalStatus {
  renderer: "webgl" | "dom";
  cols: number;
  rows: number;
  shell?: string;
  exitCode?: number;
}

export interface TerminalPaneProps {
  /** Hidden panes keep their session but skip fitting until shown. */
  active?: boolean;
  onStatus?: (status: TerminalStatus) => void;
}

/**
 * xterm.js wired to a main-process PTY. Output goes straight from the IPC
 * listener into xterm; nothing per chunk touches React state.
 */
export function TerminalPane({ active = true, onStatus }: TerminalPaneProps) {
  const hostRef = useRef<HTMLDivElement>(null);
  const fitRef = useRef<(() => void) | null>(null);
  const termRef = useRef<Terminal | null>(null);
  const statusRef = useRef(onStatus);
  statusRef.current = onStatus;

  useEffect(() => {
    const host = hostRef.current;
    const bridge = window.unshell?.terminal;
    if (!host) return;

    const term = new Terminal({
      fontFamily: terminalFont,
      fontSize: 13,
      lineHeight: 1.2,
      cursorBlink: true,
      cursorStyle: "bar",
      scrollback: 10_000,
      macOptionIsMeta: true,
      allowProposedApi: true,
      // Box drawing and powerline separators are drawn by xterm to fill the
      // cell exactly; wide icons are scaled down instead of overlapping.
      customGlyphs: true,
      rescaleOverlappingGlyphs: true,
      theme: tokyoNightTerminal,
    });
    termRef.current = term;
    const fit = new FitAddon();
    term.loadAddon(fit);
    term.loadAddon(new Unicode11Addon());
    term.unicode.activeVersion = "11";
    // window.open is routed to the system browser by the main process.
    term.loadAddon(new WebLinksAddon((_event, uri) => window.open(uri)));
    term.open(host);

    const status: TerminalStatus = {
      renderer: "dom",
      cols: term.cols,
      rows: term.rows,
    };
    const report = () => statusRef.current?.({ ...status });
    try {
      const webgl = new WebglAddon();
      webgl.onContextLoss(() => {
        webgl.dispose();
        status.renderer = "dom";
        report();
      });
      term.loadAddon(webgl);
      status.renderer = "webgl";
    } catch {
      // No WebGL2: xterm keeps its DOM renderer.
    }

    const disposers: Array<() => void> = [];
    let id: number | undefined;
    let closed = false;

    // The WebGL renderer caches glyphs in a texture atlas. If a prompt icon is
    // drawn before the symbols font loads, the atlas keeps the tofu box, so
    // load the font explicitly and rebuild the atlas once it is ready.
    void document.fonts
      .load(`${term.options.fontSize ?? 13}px "${symbolsFont}"`, "\ue0b0\uf113")
      .then(() => {
        if (closed) return;
        term.clearTextureAtlas();
        term.refresh(0, term.rows - 1);
      })
      .catch(() => {});

    const resized = term.onResize(({ cols, rows }) => {
      status.cols = cols;
      status.rows = rows;
      report();
      if (id !== undefined) bridge?.resize(id, { cols, rows });
    });
    disposers.push(() => resized.dispose());

    let frame = 0;
    const refit = () => {
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(() => {
        if (host.clientWidth === 0 || host.clientHeight === 0) return;
        fit.fit();
        // A canvas that was display:none comes back blank until redrawn.
        term.refresh(0, term.rows - 1);
      });
    };
    fitRef.current = refit;
    const observer = new ResizeObserver(refit);
    observer.observe(host);
    fit.fit();

    disposers.push(() => observer.disconnect());

    if (!bridge) {
      term.write(
        "\x1b[33mNo terminal bridge here.\x1b[0m Open this screen inside the Unshell app.\r\n",
      );
    } else {
      bridge
        .create({ cols: term.cols, rows: term.rows })
        .then((info: TerminalInfo) => {
          if (closed) return bridge.kill(info.id);
          const sessionId = info.id;
          id = sessionId;
          status.shell = info.shell;
          report();
          disposers.push(
            bridge.onData(sessionId, (data) =>
              term.write(data, () => bridge.ack(sessionId, data.length)),
            ),
            bridge.onExit(sessionId, (exitCode) => {
              status.exitCode = exitCode;
              report();
              term.write(
                `\r\n\x1b[90m[process exited with code ${exitCode}]\x1b[0m\r\n`,
              );
            }),
          );
          const input = term.onData((data) => bridge.write(sessionId, data));
          disposers.push(() => input.dispose());
          // The PTY may have been created at a stale size if layout settled.
          bridge.resize(sessionId, { cols: term.cols, rows: term.rows });
        })
        .catch((error: unknown) => {
          term.write(
            `\x1b[31mCould not start a shell: ${String(error)}\x1b[0m\r\n`,
          );
        });
    }
    report();
    term.focus();

    return () => {
      closed = true;
      cancelAnimationFrame(frame);
      for (const dispose of disposers) dispose();
      if (id !== undefined) bridge?.kill(id);
      fitRef.current = null;
      termRef.current = null;
      term.dispose();
    };
  }, []);

  useEffect(() => {
    if (!active) return;
    fitRef.current?.();
    termRef.current?.focus();
  }, [active]);

  return <div ref={hostRef} className="terminal-pane" hidden={!active} />;
}
