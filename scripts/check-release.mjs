import { execFileSync } from "node:child_process";
import { readdir, readFile } from "node:fs/promises";
import { join } from "node:path";

async function inspect(directory) {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) await inspect(path);
    else if (/\.(js|cjs|html)$/.test(entry.name)) {
      const source = await readFile(path, "utf8");
      if (
        /Design language specimen|Design language|Development only|ELECTRON_RENDERER_URL/.test(
          source,
        )
      ) {
        throw new Error(`Development surface leaked into release: ${path}`);
      }
    }
  }
}
await inspect("apps/unshell-desktop/out");
// Bundling can produce code that only fails when Electron loads it (for example
// a duplicate top-level declaration), so parse the main bundle here.
execFileSync(
  process.execPath,
  ["--check", "apps/unshell-desktop/out/main/index.js"],
  {
    stdio: "inherit",
  },
);
console.log(
  "Release output excludes development routes and renderer URL overrides.",
);
