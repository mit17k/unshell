import { Command, Option } from "commander";
import { DEFAULT_API_URL } from "@unshell/contracts";
import { createClient } from "@unshell/sdk";

export function createProgram(write: (value: string) => void = console.log) {
  const program = new Command()
    .name("unshell")
    .description("Unshell tools for developers and AI agents")
    .version("0.1.0")
    .addOption(
      new Option("--api-url <url>", "local Unshell API origin")
        .env("UNSHELL_API_URL")
        .default(DEFAULT_API_URL),
    )
    .option("--json", "emit machine-readable JSON");

  program
    .command("status")
    .description("Check coordination API health")
    .action(async () => {
      const options = program.opts<{ apiUrl: string; json?: boolean }>();
      const result = await createClient(options.apiUrl).health();
      write(
        options.json
          ? JSON.stringify(result)
          : `Unshell API: ${result.status} · API v${result.apiVersion} · uptime ${result.uptimeSeconds}s`,
      );
    });
  program
    .command("capabilities")
    .description("List implemented and planned capabilities")
    .action(async () => {
      const options = program.opts<{ apiUrl: string; json?: boolean }>();
      const result = await createClient(options.apiUrl).capabilities();
      write(
        options.json
          ? JSON.stringify(result)
          : result.capabilities
              .map((item) => `${item.id}\t${item.state}\t${item.description}`)
              .join("\n"),
      );
    });
  return program;
}
