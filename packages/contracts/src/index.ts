import { z } from "zod";

export const DEFAULT_API_URL = "http://127.0.0.1:4317";
export const API_VERSION = "1";

export const healthSchema = z.object({
  status: z.literal("ok"),
  service: z.literal("unshell-api"),
  apiVersion: z.literal(API_VERSION),
  uptimeSeconds: z.number().nonnegative(),
});

export const capabilitySchema = z.object({
  id: z.enum([
    "workspaces",
    "version-control",
    "projects",
    "agents",
    "automation",
  ]),
  name: z.string(),
  description: z.string(),
  state: z.enum(["planned", "available"]),
});

export const capabilitiesSchema = z.object({
  apiVersion: z.literal(API_VERSION),
  capabilities: z.array(capabilitySchema),
});

export type Health = z.infer<typeof healthSchema>;
export type Capability = z.infer<typeof capabilitySchema>;
export type Capabilities = z.infer<typeof capabilitiesSchema>;

/** The first API is local-only; remote coordination requires an auth design. */
export function parseApiUrl(value: string): string {
  const url = new URL(value);
  if (
    url.protocol !== "http:" ||
    !["127.0.0.1", "localhost", "[::1]"].includes(url.hostname) ||
    url.username ||
    url.password ||
    url.search ||
    url.hash ||
    url.pathname !== "/"
  ) {
    throw new Error(
      "API URL must be a loopback HTTP origin, for example http://127.0.0.1:4317",
    );
  }
  return url.origin;
}
