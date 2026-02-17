# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Unshell is "Claude Code for Product Teams — with a UI instead of a terminal." It's a desktop app that wraps Claude Code (via ACP) with a purpose-built UI for product work. It replaces the need to juggle Notion, Google Docs, Figma, Canva, Miro, and a terminal by providing a single workspace where Claude Code does the heavy lifting and the UI handles rendering, editing, and organizing the outputs.

### Core Concept: Project = Folder

A project IS a folder on disk. Everything is plain markdown/HTML files. No database, no proprietary format. The `.unshell/` directory holds auto-managed metadata (`CLAUDE.md`, `project.json`, `workflow-state.json`).

### App Layout

Three-panel workspace:
- **Explorer** (left): Real filesystem tree of the project folder
- **Editor/Viewer** (center): Multi-format engine — rich markdown (TipTap), HTML wireframe viewer, slide deck viewer, Mermaid diagram renderer
- **Claude Panel** (right): ACP-connected Claude Code with Chat tab (freeform) and Workflows tab (structured multi-step pipelines)

### Key Subsystems

- **Annotation System**: Select text → floating toolbar (Discuss, Refine, Challenge, Expand, Source, Delete) → threaded conversation in Claude Panel
- **Workflow Engine**: 6 structured workflows (Idea Generation, Market Research, TAM/SAM/SOM, PRD & Spec, Pitch Deck, Wireframes) — JSON-defined state machines with step-by-step outputs
- **Phase System**: Ideation → Research → Sizing → Scoping → Documentation → Presentation (suggestions, not gates)
- **Auto-Managed Context**: `.unshell/CLAUDE.md` auto-updates with decisions, active documents, open questions, assumptions, and phase transitions
- **Callout Blocks**: `[!insight]`, `[!decision]`, `[!assumption]`, `[!question]`, `[!risk]` — structured vocabulary that Claude uses and reads automatically

### Design Principles

1. Files are the source of truth — no lock-in, no proprietary format
2. Claude is the engine, not the product — build the UI layer, don't rebuild Claude's capabilities
3. Opinionated workflows beat flexible tools
4. Context is everything — auto-managed CLAUDE.md is the most important technical feature
5. Start rough, refine later — speed of iteration over pixel-perfection
6. One project, one folder, one workspace — solo tool, no collaboration features

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

### High-Level Components

- **Electron Shell**: Three-panel React frontend (Explorer, Editor, Claude Panel)
- **Editor**: TipTap (ProseMirror-based) for markdown with custom blocks (callouts, mermaid, HTML embeds)
- **File System**: Plain files on disk + chokidar watcher — changes by Claude via ACP trigger UI updates
- **ACP Integration**: Electron main process connects to Claude Code via ACP; every message includes current CLAUDE.md as context
- **Workflow Engine**: JSON-defined state machine in main process, persisted in `.unishell/workflow-state.json`
- **Wireframe Rendering**: Sandboxed iframe/webview, no network access, viewport controls
- **Deck Rendering**: Markdown slides split on `---`, rendered as styled containers with Mermaid support

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
