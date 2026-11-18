import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["apps/**/*.test.ts", "packages/**/*.test.ts"],
    // SwiftPM checkouts (tree-sitter's web bindings) carry their own tests.
    exclude: ["**/node_modules/**", "**/dist/**", "apps/unshell-mac/.build/**"],
    environment: "node",
    restoreMocks: true,
  },
});
