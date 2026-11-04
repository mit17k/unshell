#!/usr/bin/env node
import { CommanderError } from "commander";
import { ApiError } from "@unshell/sdk";
import { createProgram } from "./program.js";

const program = createProgram();
const json = process.argv.includes("--json");
program.exitOverride();
// Keep machine-readable failures free of Commander's additional prose.
if (json) program.configureOutput({ writeErr: () => {} });
try {
  await program.parseAsync(process.argv);
} catch (error) {
  if (error instanceof CommanderError && error.exitCode === 0) {
    process.exitCode = 0;
  } else {
    const message =
      error instanceof Error ? error.message : "Unknown CLI error";
    const code = error instanceof ApiError ? error.code : "usage";
    if (json) console.error(JSON.stringify({ error: { code, message } }));
    else if (!(error instanceof CommanderError)) console.error(message);
    process.exitCode = 1;
  }
}
