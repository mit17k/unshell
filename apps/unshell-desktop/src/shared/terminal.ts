/** IPC contract between the main-process PTY host and the renderer. */
export const TerminalChannel = {
  create: "terminal:create",
  write: "terminal:write",
  resize: "terminal:resize",
  ack: "terminal:ack",
  kill: "terminal:kill",
  data: "terminal:data",
  exit: "terminal:exit",
} as const;

export interface TerminalSize {
  cols: number;
  rows: number;
}

export interface TerminalInfo {
  id: number;
  shell: string;
  pid: number;
}

export interface TerminalBridge {
  create(size: TerminalSize): Promise<TerminalInfo>;
  write(id: number, data: string): void;
  resize(id: number, size: TerminalSize): void;
  /** Tells the host how many characters the renderer has finished drawing. */
  ack(id: number, chars: number): void;
  kill(id: number): void;
  onData(id: number, listener: (data: string) => void): () => void;
  onExit(id: number, listener: (exitCode: number) => void): () => void;
}

export interface UnshellBridge {
  terminal: TerminalBridge;
}
