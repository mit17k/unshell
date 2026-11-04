import { afterEach, describe, expect, it } from "vitest";
import { capabilitiesSchema, healthSchema } from "@unshell/contracts";
import { buildApp } from "./app.js";
import { readConfig } from "./config.js";

const apps: ReturnType<typeof buildApp>[] = [];
afterEach(async () => {
  await Promise.all(apps.splice(0).map((app) => app.close()));
});
function createApp() {
  const app = buildApp();
  apps.push(app);
  return app;
}

describe("coordination API", () => {
  it("returns health conforming to the shared contract", async () => {
    const response = await createApp().inject({ url: "/health" });
    expect(response.statusCode).toBe(200);
    expect(healthSchema.parse(response.json()).status).toBe("ok");
  });
  it("reports only planned product capabilities during migration", async () => {
    const response = await createApp().inject({ url: "/v1/capabilities" });
    const result = capabilitiesSchema.parse(response.json());
    expect(result.capabilities.map((item) => item.id)).toEqual([
      "workspaces",
      "version-control",
      "projects",
      "agents",
      "automation",
    ]);
    expect(result.capabilities.every((item) => item.state === "planned")).toBe(
      true,
    );
  });
  it("rejects browser-origin requests without enabling CORS", async () => {
    const response = await createApp().inject({
      url: "/health",
      headers: { origin: "https://untrusted.test" },
    });
    expect(response.statusCode).toBe(403);
    expect(response.headers["access-control-allow-origin"]).toBeUndefined();
  });
  it("returns 404 for unimplemented routes", async () => {
    const response = await createApp().inject({
      method: "POST",
      url: "/v1/workspaces",
      payload: { name: "example" },
    });
    expect(response.statusCode).toBe(404);
  });
});

describe("API configuration", () => {
  it("always binds loopback and defaults to port 4317", () => {
    expect(readConfig({})).toEqual({ host: "127.0.0.1", port: 4317 });
    expect(readConfig({ UNSHELL_API_PORT: "4567" }).port).toBe(4567);
  });
  it.each(["", "0", "-1", "65536", "123abc", "1.5", " 4317"])(
    "rejects invalid port %s",
    (value) => {
      expect(() => readConfig({ UNSHELL_API_PORT: value })).toThrow(
        "UNSHELL_API_PORT",
      );
    },
  );
});
