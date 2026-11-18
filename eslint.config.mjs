import js from "@eslint/js";
import tseslint from "typescript-eslint";
import globals from "globals";

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
      "apps/unshell-mac/Resources/Samples/**",
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  { languageOptions: { globals: globals.node } },
);
