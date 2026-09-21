# Unshell documentation

This directory contains durable project documentation that does not belong in crate-level Rust documentation or the root
project overview.

## Contents

- [Development workflow](development.md) explains the supported toolchain and quality gates.

## Documentation conventions

- Write Markdown compatible with CommonMark.
- Wrap prose at 120 columns. Fenced code blocks and tables are exempt.
- Use ATX headings (`# Heading`) and fenced code blocks with backticks.
- Run `just format` after editing documentation.
- Run `just lint` before opening a pull request.
