# Unshell

An Electron application built with React, TypeScript, and Tailwind CSS.

## Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- [direnv](https://direnv.net/) (optional, for automatic environment loading)

## Getting Started

```bash
# Initialize the development environment
just init

# Install dependencies
just deps

# Start the development server
just server
```

## Available Commands

| Command             | Description                              |
| ------------------- | ---------------------------------------- |
| `just init`         | Initialize direnv environment            |
| `just deps`         | Install all dependencies                 |
| `just server`       | Start development server                 |
| `just build`        | Build for production                     |
| `just format`       | Format code with Prettier                |
| `just format-check` | Check code formatting                    |
| `just lint`         | Fix linting issues                       |
| `just lint-check`   | Check for linting issues                 |
| `just test`         | Run tests                                |

## Tech Stack

- **Runtime**: Electron
- **Framework**: React 19
- **Language**: TypeScript
- **Styling**: Tailwind CSS v4 + shadcn/ui
- **State Management**: Zustand
- **Build Tool**: Vite (electron-vite)
- **Testing**: Vitest + Testing Library
- **Package Manager**: pnpm
- **Environment**: Nix Flakes

## Project Structure

```
src/
├── main/           # Electron main process
│   └── index.ts
├── preload/        # Electron preload scripts
│   └── index.ts
└── renderer/       # React application
    ├── components/
    │   └── ui/     # shadcn/ui components
    ├── hooks/      # Custom React hooks
    ├── stores/     # Zustand stores
    ├── styles/     # Global styles
    ├── utils/      # Utility functions
    ├── App.tsx
    └── main.tsx
```

## Adding shadcn Components

```bash
npx shadcn@latest add <component-name>
```

## Path Aliases

| Alias          | Path                        |
| -------------- | --------------------------- |
| `@/*`          | `src/renderer/*`            |
| `@components/*`| `src/renderer/components/*` |
| `@hooks/*`     | `src/renderer/hooks/*`      |
| `@stores/*`    | `src/renderer/stores/*`     |
| `@utils/*`     | `src/renderer/utils/*`      |
