import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { buildApp } from "../../unshell-api/src/app.js";
import { createProgram } from "./program.js";

const app = buildApp();
let apiUrl: string;
beforeAll(async () => {
  apiUrl = await app.listen({ host: "127.0.0.1", port: 0 });
});
afterAll(async () => {
  await app.close();
});
const cli = fileURLToPath(new URL("./index.ts", import.meta.url));
const execute = promisify(execFile);

describe("CLI against the live coordination API", () => {
  it("emits structured status", async () => {
    const output: string[] = [];
    await createProgram((line) => output.push(line)).parseAsync(
      ["status", "--api-url", apiUrl, "--json"],
      { from: "user" },
    );
    expect(JSON.parse(output.join(""))).toMatchObject({
      status: "ok",
      service: "unshell-api",
    });
  });
  it("lists the shared capabilities", async () => {
    const output: string[] = [];
    await createProgram((line) => output.push(line)).parseAsync(
      ["--api-url", apiUrl, "capabilities"],
      { from: "user" },
    );
    expect(output.join("")).toContain("workspaces\tplanned");
  });
  it("supports an agent invoking the entry point with an environment override", async () => {
    const { stdout, stderr } = await execute(
      process.execPath,
      ["--import", "tsx", cli, "status", "--json"],
      { env: { ...process.env, UNSHELL_API_URL: apiUrl } },
    );
    expect(JSON.parse(stdout)).toMatchObject({ status: "ok" });
    expect(stderr).toBe("");
  });
  it("returns JSON on stderr and exits nonzero when the API is unavailable", async () => {
    const temporary = buildApp();
    const unavailable = await temporary.listen({ host: "127.0.0.1", port: 0 });
    await temporary.close();
    await expect(
      execute(process.execPath, [
        "--import",
        "tsx",
        cli,
        "status",
        "--json",
        "--api-url",
        unavailable,
      ]),
    ).rejects.toMatchObject({
      code: 1,
      stdout: "",
      stderr: expect.stringContaining('"code":"connection"'),
    });
  });
  it("returns machine-readable usage errors", async () => {
    await expect(
      execute(process.execPath, ["--import", "tsx", cli, "unknown", "--json"]),
    ).rejects.toMatchObject({
      code: 1,
      stdout: "",
      stderr: expect.stringContaining('"code":"usage"'),
    });
  });
});
