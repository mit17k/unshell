import { contextBridge, ipcRenderer } from "electron";
import {
  TerminalChannel,
  type TerminalBridge,
  type UnshellBridge,
} from "../shared/terminal.js";

// One IPC listener per channel, fanned out by terminal id, so a busy terminal
// costs one message per output batch rather than one per listener.
const dataListeners = new Map<number, (data: string) => void>();
const exitListeners = new Map<number, (exitCode: number) => void>();
ipcRenderer.on(TerminalChannel.data, (_event, id: number, data: string) =>
  dataListeners.get(id)?.(data),
);
ipcRenderer.on(TerminalChannel.exit, (_event, id: number, exitCode: number) =>
  exitListeners.get(id)?.(exitCode),
);

const terminal: TerminalBridge = {
  create: (size) => ipcRenderer.invoke(TerminalChannel.create, size),
  write: (id, data) => ipcRenderer.send(TerminalChannel.write, id, data),
  resize: (id, size) => ipcRenderer.send(TerminalChannel.resize, id, size),
  ack: (id, chars) => ipcRenderer.send(TerminalChannel.ack, id, chars),
  kill: (id) => {
    dataListeners.delete(id);
    exitListeners.delete(id);
    ipcRenderer.send(TerminalChannel.kill, id);
  },
  onData: (id, listener) => {
    dataListeners.set(id, listener);
    return () => dataListeners.delete(id);
  },
  onExit: (id, listener) => {
    exitListeners.set(id, listener);
    return () => exitListeners.delete(id);
  },
};

const bridge: UnshellBridge = { terminal };
contextBridge.exposeInMainWorld("unshell", bridge);
