import { beforeEach, describe, expect, it } from "vitest";

import { useAppStore } from "./app-store";

describe("useAppStore", () => {
  beforeEach(() => {
    useAppStore.setState({ count: 0, title: "Unshell" });
  });

  it("should have initial state", () => {
    const state = useAppStore.getState();
    expect(state.count).toBe(0);
    expect(state.title).toBe("Unshell");
  });

  it("should increment count", () => {
    useAppStore.getState().increment();
    expect(useAppStore.getState().count).toBe(1);
  });

  it("should decrement count", () => {
    useAppStore.getState().increment();
    useAppStore.getState().increment();
    useAppStore.getState().decrement();
    expect(useAppStore.getState().count).toBe(1);
  });

  it("should set title", () => {
    useAppStore.getState().setTitle("New Title");
    expect(useAppStore.getState().title).toBe("New Title");
  });
});
