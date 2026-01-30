import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { defineConfig } from "electron-vite";

const __dirname = dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  main: {
    build: {
      outDir: "dist/main",
      rollupOptions: {
        input: {
          index: "src/main/index.ts",
        },
      },
    },
  },
  preload: {
    build: {
      outDir: "dist/preload",
      rollupOptions: {
        input: {
          index: "src/preload/index.ts",
        },
      },
    },
  },
  renderer: {
    plugins: [react(), tailwindcss()],
    resolve: {
      alias: {
        "@": resolve(__dirname, "src/renderer"),
        "@components": resolve(__dirname, "src/renderer/components"),
        "@hooks": resolve(__dirname, "src/renderer/hooks"),
        "@stores": resolve(__dirname, "src/renderer/stores"),
        "@utils": resolve(__dirname, "src/renderer/utils"),
      },
    },
    build: {
      outDir: "dist/renderer",
      rollupOptions: {
        input: {
          index: "src/renderer/index.html",
        },
      },
    },
  },
});
