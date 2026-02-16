# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Unshell is "Cursor for product teams" — a desktop app that brings Claude's agentic workflows into a purpose-built GUI for product managers, designers, and analysts. Just as Cursor embedded AI into the developer's code editor to transform software engineering workflows, Unshell embeds AI into a product workspace to transform product team workflows. It uses the Claude Agent SDK locally with users' existing Claude Pro/Max subscriptions (no API keys needed). The core value proposition: eliminate the CLI barrier and context-switching tax that prevent product teams from leveraging AI at the same depth developers do.

## Development Commands

```bash
just              # List all commands
just deps         # Install dependencies (run after clone/pull)
just server       # Start dev server
just build        # Build for production
just test         # Run tests
just lint         # Fix linting issues
just format       # Format code
```

Run a single test file:
```bash
pnpm vitest run src/renderer/stores/app-store.test.ts
```

Watch mode for tests:
```bash
pnpm test:watch
```

## Architecture

### Electron Process Model

Three separate build targets configured in `electron.vite.config.ts`:

- **Main Process** (`src/main/`): Node.js environment for system operations. Entry: `src/main/index.ts`
- **Preload Scripts** (`src/preload/`): Context bridge exposing `window.electronAPI` to renderer. Entry: `src/preload/index.ts`
- **Renderer Process** (`src/renderer/`): React app running in Chromium. Entry: `src/renderer/main.tsx`

### IPC Communication

Use the exposed `electronAPI` in renderer:
```typescript
window.electronAPI.send(channel, data)         // one-way to main
window.electronAPI.invoke(channel, data)       // request/response
window.electronAPI.receive(channel, callback)  // listen from main
```

### State Management

Zustand stores in `src/renderer/stores/`. Pattern from `app-store.ts`:
```typescript
interface MyState {
  value: string;
  setValue: (value: string) => void;
}

export const useMyStore = create<MyState>((set) => ({
  value: "",
  setValue: (value) => set({ value }),
}));
```

### Path Aliases

Always use these aliases for imports:
- `@components/*` → `src/renderer/components/*`
- `@hooks/*` → `src/renderer/hooks/*`
- `@stores/*` → `src/renderer/stores/*`
- `@utils/*` → `src/renderer/utils/*`

### Styling

- Tailwind CSS v4 with CSS-first configuration
- shadcn/ui components in `src/renderer/components/ui/`
- Use `cn()` from `@utils/cn` for conditional classes
- Theme variables in `src/renderer/styles/globals.css`
- Add shadcn components: `npx shadcn@latest add <component-name>`

## Code Conventions

- TypeScript strict mode enabled
- Use `interface` for object shapes, `type` for unions/intersections
- Functional components with named exports
- Tests co-located with source files (`*.test.ts` / `*.test.tsx`)
- Vitest + Testing Library for testing
