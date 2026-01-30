import { resolve } from "path";
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./vitest.setup.ts"],
  },
  resolve: {
    alias: {
      "@": resolve(__dirname, "src/renderer"),
      "@components": resolve(__dirname, "src/renderer/components"),
      "@hooks": resolve(__dirname, "src/renderer/hooks"),
      "@stores": resolve(__dirname, "src/renderer/stores"),
      "@utils": resolve(__dirname, "src/renderer/utils"),
    },
  },
});
