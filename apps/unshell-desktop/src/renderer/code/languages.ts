import type { LanguageRegistration } from "shiki/core";

type LanguageModule = { default: LanguageRegistration[] };

export interface Language {
  /** Shiki grammar id. */
  id: string;
  label: string;
  load: () => Promise<LanguageModule>;
}

// Grammars load on demand, so each one is its own chunk.
export const languages: Language[] = [
  {
    id: "typescript",
    label: "TypeScript",
    load: () => import("shiki/langs/typescript.mjs"),
  },
  { id: "tsx", label: "TSX", load: () => import("shiki/langs/tsx.mjs") },
  {
    id: "javascript",
    label: "JavaScript",
    load: () => import("shiki/langs/javascript.mjs"),
  },
  {
    id: "python",
    label: "Python",
    load: () => import("shiki/langs/python.mjs"),
  },
  { id: "go", label: "Go", load: () => import("shiki/langs/go.mjs") },
  { id: "rust", label: "Rust", load: () => import("shiki/langs/rust.mjs") },
  { id: "java", label: "Java", load: () => import("shiki/langs/java.mjs") },
  {
    id: "kotlin",
    label: "Kotlin",
    load: () => import("shiki/langs/kotlin.mjs"),
  },
  { id: "swift", label: "Swift", load: () => import("shiki/langs/swift.mjs") },
  { id: "c", label: "C", load: () => import("shiki/langs/c.mjs") },
  { id: "cpp", label: "C++", load: () => import("shiki/langs/cpp.mjs") },
  { id: "csharp", label: "C#", load: () => import("shiki/langs/csharp.mjs") },
  { id: "ruby", label: "Ruby", load: () => import("shiki/langs/ruby.mjs") },
  { id: "php", label: "PHP", load: () => import("shiki/langs/php.mjs") },
  {
    id: "elixir",
    label: "Elixir",
    load: () => import("shiki/langs/elixir.mjs"),
  },
  {
    id: "shellscript",
    label: "Shell",
    load: () => import("shiki/langs/shellscript.mjs"),
  },
  { id: "sql", label: "SQL", load: () => import("shiki/langs/sql.mjs") },
  { id: "html", label: "HTML", load: () => import("shiki/langs/html.mjs") },
  { id: "css", label: "CSS", load: () => import("shiki/langs/css.mjs") },
  { id: "json", label: "JSON", load: () => import("shiki/langs/json.mjs") },
  { id: "yaml", label: "YAML", load: () => import("shiki/langs/yaml.mjs") },
  { id: "toml", label: "TOML", load: () => import("shiki/langs/toml.mjs") },
  {
    id: "markdown",
    label: "Markdown",
    load: () => import("shiki/langs/markdown.mjs"),
  },
  {
    id: "dockerfile",
    label: "Dockerfile",
    load: () => import("shiki/langs/dockerfile.mjs"),
  },
  { id: "nix", label: "Nix", load: () => import("shiki/langs/nix.mjs") },
];

export function findLanguage(id: string) {
  return languages.find((language) => language.id === id);
}
