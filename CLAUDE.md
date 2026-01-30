# Claude Code Context

This file provides context for Claude when working on the Unshell project.

## Project Overview

**Unshell** — _The Product Team's Command Center for Claude._

Unshell is a specialized desktop interface that brings the power of Claude's agentic workflows out of the terminal and
into a high-productivity GUI. Built for product teams, it eliminates the "CLI barrier," allowing non-technical
stakeholders to execute complex, multi-step workflows using their existing Claude Pro or Max subscriptions.

### Technical Architecture

- **Engine**: Electron desktop application (React, TypeScript, Tailwind CSS)
- **Intelligence**: Claude Agent SDK (runs locally on user's machine)
- **Bridge**: Agent Client Protocol (ACP) for GUI-agent communication, MCP for internal data connections
- **Cost Model**: $0 API fees — usage billed against users' existing subscription quotas
- **Auth**: One-time `claude login` triggered by the app

### Key Features

- **Bring Your Own Subscription (BYOS)**: Connects to local Claude credentials — no API keys, no per-token billing
- **Action Cards**: One-click buttons for common product workflows (Spec-to-Ticket, Roadmap Refiner, "Roast" Protocol)
- **MCP Integration**: Connects to internal data (GitHub, Jira, Notion, custom DBs) via Model Context Protocol
- **Local-First Privacy**: All processing on user's machine — internal data never touches centralized servers

## Development Environment

- Uses Nix flakes for reproducible development environment
- Run `just` to see all available commands
- Always use `just deps` after cloning or pulling changes

## Architecture

### Process Model

- **Main Process** (`src/main/`): Node.js environment, handles system-level operations
- **Preload Scripts** (`src/preload/`): Bridge between main and renderer, exposes safe APIs
- **Renderer Process** (`src/renderer/`): React application, runs in Chromium

### State Management

- Use Zustand for global state (`src/renderer/stores/`)
- Stores should be typed and use the pattern in `app-store.ts`

### Styling

- Tailwind CSS v4 with CSS-first configuration
- shadcn/ui components in `src/renderer/components/ui/`
- Use the `cn()` utility from `@utils/cn` for conditional classes
- Theme variables defined in `src/renderer/styles/globals.css`

### Path Aliases

Always use path aliases for imports:

- `@components/*` for components
- `@hooks/*` for custom hooks
- `@stores/*` for Zustand stores
- `@utils/*` for utilities

## Code Conventions

### TypeScript

- Strict mode enabled
- Prefer explicit types over inference for function parameters
- Use `interface` for object shapes, `type` for unions/intersections

### React

- Functional components only
- Use named exports for components
- Hooks should be prefixed with `use`

### Testing

- Tests co-located with source files (`*.test.ts` / `*.test.tsx`)
- Use Vitest + Testing Library
- Run tests with `just test`

### Formatting & Linting

- Prettier for formatting (run `just format`)
- ESLint for linting (run `just lint`)
- Import sorting handled by prettier-plugin-sort-imports

## Common Tasks

### Adding a New Component

1. Create component in `src/renderer/components/`
2. Use shadcn/ui primitives when applicable
3. Export from component file

### Adding a New Store

1. Create store in `src/renderer/stores/`
2. Follow the pattern in `app-store.ts`
3. Add corresponding test file

### Adding shadcn Components

```bash
npx shadcn@latest add <component-name>
```

## IPC Communication

Use the exposed `electronAPI` in renderer:

- `window.electronAPI.send(channel, data)` - one-way to main
- `window.electronAPI.invoke(channel, data)` - request/response
- `window.electronAPI.receive(channel, callback)` - listen from main
