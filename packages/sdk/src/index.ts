import {
  DEFAULT_API_URL,
  capabilitiesSchema,
  healthSchema,
  parseApiUrl,
  type Capabilities,
  type Health,
} from "@unshell/contracts";

export class ApiError extends Error {
  constructor(
    message: string,
    public readonly code: "connection" | "http" | "contract",
  ) {
    super(message);
    this.name = "ApiError";
  }
}

export function createClient(apiUrl = DEFAULT_API_URL, timeoutMs = 5000) {
  const baseUrl = parseApiUrl(apiUrl);

  async function request<T>(
    path: string,
    schema: { parse(value: unknown): T },
  ): Promise<T> {
    let response: Response;
    try {
      response = await fetch(`${baseUrl}${path}`, {
        signal: AbortSignal.timeout(timeoutMs),
        redirect: "error",
        headers: { accept: "application/json" },
      });
    } catch {
      throw new ApiError(
        `Cannot reach Unshell API at ${baseUrl}. Start unshell-api and retry.`,
        "connection",
      );
    }
    if (!response.ok) {
      throw new ApiError(
        `Unshell API returned HTTP ${response.status}`,
        "http",
      );
    }
    try {
      return schema.parse(await response.json());
    } catch {
      throw new ApiError(
        "Unshell API returned an incompatible response. Check that client and API versions match.",
        "contract",
      );
    }
  }

  return {
    baseUrl,
    health: (): Promise<Health> => request("/health", healthSchema),
    capabilities: (): Promise<Capabilities> =>
      request("/v1/capabilities", capabilitiesSchema),
  };
}
export type UnshellClient = ReturnType<typeof createClient>;
