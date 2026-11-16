import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { PtyHost, type PtyProcess } from "./pty-host.js";

function fakePty() {
  let emit: (data: string) => void = () => {};
  let exit: (event: { exitCode: number }) => void = () => {};
  const pty = {
    pid: 42,
    onData: (listener: (data: string) => void) => (
      (emit = listener),
      { dispose() {} }
    ),
    onExit: (listener: (event: { exitCode: number }) => void) => (
      (exit = listener),
      { dispose() {} }
    ),
    write: vi.fn(),
    resize: vi.fn(),
    pause: vi.fn(),
    resume: vi.fn(),
    kill: vi.fn(),
  } satisfies PtyProcess;
  return {
    pty,
    emit: (data: string) => emit(data),
    exit: (exitCode: number) => exit({ exitCode }),
  };
}

describe("PtyHost", () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  function setup(
    options: { highWater?: number; lowWater?: number; maxBatch?: number } = {},
  ) {
    const fake = fakePty();
    const send = vi.fn();
    const host = new PtyHost({
      shell: "/bin/zsh",
      spawn: () => fake.pty,
      send,
      ...options,
    });
    const { id } = host.create({ cols: 80, rows: 24 });
    return { fake, send, host, id };
  }

  it("coalesces output into one message per flush", () => {
    const { fake, send, id } = setup();
    fake.emit("a");
    fake.emit("b");
    fake.emit("c");
    expect(send).not.toHaveBeenCalled();
    vi.advanceTimersByTime(5);
    expect(send).toHaveBeenCalledExactlyOnceWith("data", id, "abc");
  });

  it("flushes early when a batch is full", () => {
    const { fake, send, id } = setup({ maxBatch: 4 });
    fake.emit("12345");
    expect(send).toHaveBeenCalledWith("data", id, "12345");
  });

  it("pauses the pty above the high-water mark and resumes after acks", () => {
    const { fake, host, id } = setup({
      maxBatch: 10,
      highWater: 15,
      lowWater: 5,
    });
    fake.emit("x".repeat(10));
    expect(fake.pty.pause).not.toHaveBeenCalled();
    fake.emit("x".repeat(10));
    expect(fake.pty.pause).toHaveBeenCalledOnce();
    host.ack(id, 10);
    expect(fake.pty.resume).not.toHaveBeenCalled();
    host.ack(id, 8);
    expect(fake.pty.resume).toHaveBeenCalledOnce();
  });

  it("flushes pending output before reporting exit", () => {
    const { fake, send, host, id } = setup();
    fake.emit("bye");
    fake.exit(0);
    expect(send.mock.calls).toEqual([
      ["data", id, "bye"],
      ["exit", id, 0],
    ]);
    expect(host.size).toBe(0);
  });

  it("rejects bad sizes and input", () => {
    const { fake, host, id } = setup();
    expect(() => host.create({ cols: 0, rows: 24 })).toThrow();
    host.resize(id, { cols: 5000, rows: 10 });
    host.write(id, 123);
    expect(fake.pty.resize).not.toHaveBeenCalled();
    expect(fake.pty.write).not.toHaveBeenCalled();
  });

  it("kills every session on dispose", () => {
    const { fake, host } = setup();
    host.dispose();
    expect(fake.pty.kill).toHaveBeenCalledOnce();
    expect(host.size).toBe(0);
  });
});
