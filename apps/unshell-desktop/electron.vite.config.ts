import { defineConfig } from "electron-vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  main: {
    build: { externalizeDeps: false },
  },
  preload: {
    build: {
      externalizeDeps: false,
      rollupOptions: { output: { format: "cjs", entryFileNames: "index.cjs" } },
    },
  },
  renderer: {
    plugins: [
      react(),
      {
        name: "development-csp",
        apply: "serve",
        // React refresh injects an inline preamble; production retains the
        // restrictive policy in index.html and has no local websocket access.
        transformIndexHtml(html) {
          return html
            .replace("script-src 'self'", "script-src 'self' 'unsafe-inline'")
            .replace(
              "connect-src 'self'",
              "connect-src 'self' ws://127.0.0.1:*",
            );
        },
      },
    ],
    server: { host: "127.0.0.1" },
  },
});
