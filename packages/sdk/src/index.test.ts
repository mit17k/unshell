import { afterEach, describe, expect, it, vi } from "vitest";
import { createClient } from "./index.js";

afterEach(() => vi.unstubAllGlobals());

describe("API client failure boundaries", () => {
  it("reports connection errors without leaking the raw transport error", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockRejectedValue(new Error("socket internals")),
    );
    await expect(createClient().health()).rejects.toMatchObject({
      code: "connection",
    });
  });
  it("reports HTTP errors", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(new Response("", { status: 503 })),
    );
    await expect(createClient().health()).rejects.toMatchObject({
      code: "http",
    });
  });
  it.each([
    { status: "ok", service: "another-api", apiVersion: "1", uptimeSeconds: 0 },
    { status: "ok", service: "unshell-api", apiVersion: "2", uptimeSeconds: 0 },
  ])("rejects incompatible response %j", async (body) => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(Response.json(body)));
    await expect(createClient().health()).rejects.toMatchObject({
      code: "contract",
    });
  });
  it("sets a timeout and refuses redirects", async () => {
    const fetch = vi.fn().mockResolvedValue(
      Response.json({
        status: "ok",
        service: "unshell-api",
        apiVersion: "1",
        uptimeSeconds: 10,
      }),
    );
    vi.stubGlobal("fetch", fetch);
    await expect(createClient().health()).resolves.toMatchObject({
      status: "ok",
    });
    expect(fetch).toHaveBeenCalledWith(
      "http://127.0.0.1:4317/health",
      expect.objectContaining({
        signal: expect.any(AbortSignal),
        redirect: "error",
      }),
    );
  });
});
