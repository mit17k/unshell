import { readdir, stat } from "node:fs/promises";
import { join } from "node:path";

export type WorkspaceState = "clean" | "dirty" | "syncing";

export interface Workspace {
  readonly id: string;
  name: string;
  repos: string[];
  state: WorkspaceState;
}

/** Lists managed workspaces under a root directory. */
export async function listWorkspaces(root: string): Promise<Workspace[]> {
  const entries = await readdir(root, { withFileTypes: true });
  const workspaces: Workspace[] = [];
  for (const entry of entries) {
    if (!entry.isDirectory() || entry.name.startsWith(".")) continue;
    const repos = await readdir(join(root, entry.name, "repos")).catch(() => []);
    workspaces.push({ id: crypto.randomUUID(), name: entry.name, repos, state: "clean" });
  }
  return workspaces.sort((a, b) => a.name.localeCompare(b.name));
}

export const isStale = async (path: string, maxAgeMs = 86_400_000) =>
  Date.now() - (await stat(path)).mtimeMs > maxAgeMs;
