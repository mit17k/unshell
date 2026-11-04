export function readConfig(env: NodeJS.ProcessEnv = process.env) {
  const port = env.UNSHELL_API_PORT ?? "4317";
  if (!/^\d+$/.test(port) || Number(port) < 1 || Number(port) > 65535) {
    throw new Error("UNSHELL_API_PORT must be an integer between 1 and 65535");
  }
  return { host: "127.0.0.1", port: Number(port) };
}
