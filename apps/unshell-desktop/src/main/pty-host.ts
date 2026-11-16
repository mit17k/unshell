import type { TerminalInfo, TerminalSize } from "../shared/terminal.js";

/** The slice of node-pty's IPty the host relies on, so tests can fake it. */
export interface PtyProcess {
  readonly pid: number;
  onData(listener: (data: string) => void): { dispose(): void };
  onExit(listener: (event: { exitCode: number }) => void): { dispose(): void };
  write(data: string): void;
  resize(cols: number, rows: number): void;
  pause(): void;
  resume(): void;
  kill(signal?: string): void;
}

export interface PtyHostOptions {
  spawn(shell: string, size: TerminalSize): PtyProcess;
  shell: string;
  send(event: "data", id: number, data: string): void;
  send(event: "exit", id: number, exitCode: number): void;
  /** Output is coalesced for this long before one IPC message is sent. */
  flushMs?: number;
  /** Flush immediately once this many characters are buffered. */
  maxBatch?: number;
  /** Pause the PTY when this many characters are sent but not yet drawn. */
  highWater?: number;
  /** Resume once unacknowledged output drops below this. */
  lowWater?: number;
}

interface Session {
  pty: PtyProcess;
  buffer: string;
  timer: ReturnType<typeof setTimeout> | undefined;
  unacked: number;
  paused: boolean;
}

const MAX_DIMENSION = 1000;
const MAX_WRITE = 1 << 20;

export function validSize(size: unknown): size is TerminalSize {
  if (typeof size !== "object" || size === null) return false;
  const { cols, rows } = size as Record<string, unknown>;
  return [cols, rows].every(
    (n) =>
      Number.isInteger(n) &&
      (n as number) > 0 &&
      (n as number) <= MAX_DIMENSION,
  );
}

/**
 * Owns the PTYs for one renderer. Output is batched to keep IPC traffic low,
 * and the PTY is paused when the renderer falls behind (xterm.js flow control).
 */
export class PtyHost {
  readonly #sessions = new Map<number, Session>();
  readonly #options: Required<PtyHostOptions>;
  #nextId = 1;

  constructor(options: PtyHostOptions) {
    this.#options = {
      flushMs: 5,
      maxBatch: 64 * 1024,
      highWater: 512 * 1024,
      lowWater: 64 * 1024,
      ...options,
    };
  }

  create(size: TerminalSize): TerminalInfo {
    if (!validSize(size)) throw new Error("Invalid terminal size");
    const id = this.#nextId++;
    const pty = this.#options.spawn(this.#options.shell, size);
    const session: Session = {
      pty,
      buffer: "",
      timer: undefined,
      unacked: 0,
      paused: false,
    };
    this.#sessions.set(id, session);

    pty.onData((data) => {
      session.buffer += data;
      if (session.buffer.length >= this.#options.maxBatch) this.#flush(id);
      else
        session.timer ??= setTimeout(
          () => this.#flush(id),
          this.#options.flushMs,
        );
    });
    pty.onExit(({ exitCode }) => {
      this.#flush(id);
      this.#sessions.delete(id);
      this.#options.send("exit", id, exitCode);
    });
    return { id, shell: this.#options.shell, pid: pty.pid };
  }

  write(id: number, data: unknown) {
    if (typeof data !== "string" || data.length > MAX_WRITE) return;
    this.#sessions.get(id)?.pty.write(data);
  }

  resize(id: number, size: unknown) {
    if (validSize(size))
      this.#sessions.get(id)?.pty.resize(size.cols, size.rows);
  }

  ack(id: number, chars: unknown) {
    const session = this.#sessions.get(id);
    if (!session || typeof chars !== "number" || !(chars > 0)) return;
    session.unacked = Math.max(0, session.unacked - chars);
    if (session.paused && session.unacked < this.#options.lowWater) {
      session.paused = false;
      session.pty.resume();
    }
  }

  kill(id: number) {
    const session = this.#sessions.get(id);
    if (!session) return;
    clearTimeout(session.timer);
    this.#sessions.delete(id);
    session.pty.kill();
  }

  dispose() {
    for (const id of [...this.#sessions.keys()]) this.kill(id);
  }

  get size() {
    return this.#sessions.size;
  }

  #flush(id: number) {
    const session = this.#sessions.get(id);
    if (!session) return;
    clearTimeout(session.timer);
    session.timer = undefined;
    if (!session.buffer) return;
    const chunk = session.buffer;
    session.buffer = "";
    session.unacked += chunk.length;
    this.#options.send("data", id, chunk);
    if (!session.paused && session.unacked > this.#options.highWater) {
      session.paused = true;
      session.pty.pause();
    }
  }
}
