// Sample files are plain text: they are excluded from type checks, lint and
// formatting so they stay realistic. Vite inlines each one as a lazy chunk.

export interface Sample {
  filename: string;
  load: () => Promise<{ default: string }>;
}

export const samples: Record<string, Sample> = {
  typescript: {
    filename: "workspace.ts",
    load: () => import("./samples/workspace.ts?raw"),
  },
  tsx: {
    filename: "AgentCard.tsx",
    load: () => import("./samples/AgentCard.tsx?raw"),
  },
  javascript: {
    filename: "queue.js",
    load: () => import("./samples/queue.js?raw"),
  },
  python: {
    filename: "indexer.py",
    load: () => import("./samples/indexer.py?raw"),
  },
  go: { filename: "server.go", load: () => import("./samples/server.go?raw") },
  rust: { filename: "tree.rs", load: () => import("./samples/tree.rs?raw") },
  java: {
    filename: "Scheduler.java",
    load: () => import("./samples/Scheduler.java?raw"),
  },
  kotlin: {
    filename: "Projects.kt",
    load: () => import("./samples/Projects.kt?raw"),
  },
  swift: {
    filename: "Settings.swift",
    load: () => import("./samples/Settings.swift?raw"),
  },
  c: { filename: "ring.c", load: () => import("./samples/ring.c?raw") },
  cpp: { filename: "cache.cpp", load: () => import("./samples/cache.cpp?raw") },
  csharp: {
    filename: "Notifier.cs",
    load: () => import("./samples/Notifier.cs?raw"),
  },
  ruby: { filename: "hooks.rb", load: () => import("./samples/hooks.rb?raw") },
  php: {
    filename: "Router.php",
    load: () => import("./samples/Router.php?raw"),
  },
  elixir: {
    filename: "supervisor.ex",
    load: () => import("./samples/supervisor.ex?raw"),
  },
  shellscript: {
    filename: "bootstrap.sh",
    load: () => import("./samples/bootstrap.sh?raw"),
  },
  sql: {
    filename: "report.sql",
    load: () => import("./samples/report.sql?raw"),
  },
  html: {
    filename: "index.html",
    load: () => import("./samples/index.html?raw"),
  },
  css: {
    filename: "styles.css",
    load: () => import("./samples/styles.css?raw"),
  },
  json: {
    filename: "workspace.json",
    load: () => import("./samples/workspace.json?raw"),
  },
  yaml: {
    filename: "pipeline.yaml",
    load: () => import("./samples/pipeline.yaml?raw"),
  },
  toml: {
    filename: "Cargo.toml",
    load: () => import("./samples/Cargo.toml?raw"),
  },
  markdown: {
    filename: "README.md",
    load: () => import("./samples/README.md?raw"),
  },
  dockerfile: {
    filename: "Dockerfile",
    load: () => import("./samples/Dockerfile?raw"),
  },
  nix: {
    filename: "devshell.nix",
    load: () => import("./samples/devshell.nix?raw"),
  },
};
