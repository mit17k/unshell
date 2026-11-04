import Fastify from "fastify";
import {
  API_VERSION,
  type Capabilities,
  type Health,
} from "@unshell/contracts";

const capabilities: Capabilities = {
  apiVersion: API_VERSION,
  capabilities: [
    {
      id: "workspaces",
      name: "Workspaces",
      description:
        "Managed repositories, worktrees, knowledge, and development environments.",
      state: "planned",
    },
    {
      id: "version-control",
      name: "Version control",
      description:
        "Branches, diffs, commits, and review in one working context.",
      state: "planned",
    },
    {
      id: "projects",
      name: "Projects",
      description: "Project context, work tracking, and delivery coordination.",
      state: "planned",
    },
    {
      id: "agents",
      name: "Agents & harness",
      description:
        "Agent sessions, tool access, execution, and lifecycle management.",
      state: "planned",
    },
    {
      id: "automation",
      name: "Automation",
      description: "Repeatable workflows, triggers, and background jobs.",
      state: "planned",
    },
  ],
};

export function buildApp(options: { logger?: boolean } = {}) {
  const app = Fastify({ logger: options.logger ?? false });
  const started = performance.now();

  // Browser pages cannot access the local coordination API. The desktop uses
  // main-process HTTP through its narrow preload bridge, not renderer fetch.
  app.addHook("onRequest", async (request, reply) => {
    if (request.headers.origin) {
      return reply
        .code(403)
        .send({ error: "Browser-origin requests are not supported" });
    }
  });
  app.get(
    "/health",
    async (): Promise<Health> => ({
      status: "ok",
      service: "unshell-api",
      apiVersion: API_VERSION,
      uptimeSeconds: Math.floor((performance.now() - started) / 1000),
    }),
  );
  app.get("/v1/capabilities", async (): Promise<Capabilities> => capabilities);
  return app;
}
