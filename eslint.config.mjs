import js from "@eslint/js";
import tseslint from "typescript-eslint";
import globals from "globals";
import reactHooks from "eslint-plugin-react-hooks";

export default tseslint.config(
  {
    ignores: [
      "**/node_modules/**",
      "**/dist/**",
      "**/out/**",
      "**/release/**",
      "target/**",
      ".direnv/**",
      ".pnpm-store/**",
      ".delta/**",
      ".cache/**",
      "apps/unshell-mac/.build/**",
      "apps/unshell-mac/Vendor/**",
      "apps/unshell-desktop/src/renderer/dev/samples/**",
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  { languageOptions: { globals: globals.node } },
  {
    files: ["apps/unshell-desktop/src/renderer/**/*.{ts,tsx}"],
    languageOptions: { globals: globals.browser },
    plugins: { "react-hooks": reactHooks },
    rules: {
      "react-hooks/rules-of-hooks": "error",
      "react-hooks/exhaustive-deps": "error",
    },
  },
);
