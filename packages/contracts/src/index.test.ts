import { describe, expect, it } from "vitest";
import { parseApiUrl } from "./index.js";

describe("local API origins", () => {
  it.each([
    "http://127.0.0.1:4317",
    "http://localhost:4317/",
    "http://[::1]:4317",
  ])("accepts %s", (url) => {
    expect(parseApiUrl(url)).toBe(new URL(url).origin);
  });
  it.each([
    "https://example.com",
    "http://0.0.0.0:4317",
    "http://localhost.evil.test",
    "http://user:secret@localhost",
    "http://localhost/path",
    "http://localhost?key=secret",
    "http://localhost#fragment",
    "file:///tmp/api",
    "not a url",
  ])("rejects %s", (url) => {
    expect(() => parseApiUrl(url)).toThrow();
  });
});
