# Unshell

**Claude Code for Product Teams — with a UI instead of a terminal.**

Unshell is a desktop app that wraps Claude Code (via ACP) with a purpose-built UI for product work. It eliminates the need to juggle Notion, Google Docs, Figma, Canva, Miro, and a terminal by providing a single workspace where Claude Code does the heavy lifting and the UI handles rendering, editing, and organizing the outputs.

## The Key Insight

Claude Code already knows how to write PRDs, generate wireframes as HTML, create pitch decks, do market research, draw Mermaid diagrams, and build mind maps. The problem is that accessing all of this through a terminal sucks for product work. Unshell is the UI layer that makes Claude Code's product capabilities accessible.

| Tool | Unshell Equivalent |
| ---- | ------------------ |
| Notion / Google Docs | Markdown editor with rich rendering |
| Figma (rough wireframes) | HTML wireframes rendered inline |
| Canva (decks) | Markdown-driven slide presentations |
| Miro (mind maps) | Mermaid + HTML mind maps in docs |
| Terminal Claude Code | Visual side panel with project context |
| Manual CLAUDE.md setup | Auto-managed project context |

## Core Concept: Project = Folder

When you create a project, Unshell asks you to select or create a directory on your Mac. That's it. The project IS the folder. Everything is plain files. If Unshell dies tomorrow, your work survives.

```
~/projects/my-saas-idea/
├── .unshell/
│   ├── CLAUDE.md              ← Auto-managed, always up to date
│   ├── project.json           ← Metadata, phase, settings
│   └── workflow-state.json    ← Active workflow progress
├── research/
│   ├── market-landscape.md
│   ├── competitors.md
│   └── tam-sam-som.md
├── docs/
│   ├── prd.md
│   ├── user-personas.md
│   └── user-journeys.md
├── wireframes/
│   ├── landing-page.html
│   ├── dashboard.html
│   └── onboarding-flow.html
├── decks/
│   ├── pitch-deck.md          ← Markdown slides with --- separators
│   └── investor-update.md
└── notes/
    ├── brainstorm-jan15.md
    └── meeting-notes.md
```

## App Layout

Three-panel workspace where you live 99% of the time:

- **Explorer** (left) — Real filesystem tree of the project folder
- **Editor/Viewer** (center) — Multi-format engine that detects file type and renders accordingly
- **Claude Panel** (right) — ACP-connected Claude Code with Chat and Workflow tabs

### Editor Modes

| File Type | Rendering |
| --------- | --------- |
| `.md` files | Rich inline markdown (TipTap) with Mermaid, callout blocks, embedded HTML |
| `.html` in `/wireframes/` | Live HTML preview with viewport controls (desktop/tablet/mobile) |
| `.md` in `/decks/` | Slide presentation view with navigation and fullscreen mode |
| `.mermaid` files | Interactive diagram rendering |

### Annotation System

Select text in any document (or click an element in a wireframe) to get a floating toolbar: Discuss, Refine, Challenge, Expand, Source, Delete. Each action opens a threaded conversation in the Claude Panel with the selection as context.

### Claude Panel

**Chat tab** — Freeform conversation with full project awareness. Claude knows which file is open, the full project context from `.unshell/CLAUDE.md`, the file tree, and the current phase. Claude can create/edit files, search the web, and generate any output format.

**Workflows tab** — Structured multi-step pipelines that produce specific outputs:

1. **Idea Generation & Validation** — Problem canvas, idea angles, validation matrix, decision doc
2. **Market Research & Competitive Analysis** — Market landscape, competitor deep dive, gap analysis, opportunity brief
3. **TAM/SAM/SOM Sizing** — Assumptions log, top-down model, bottom-up model, sizing summary
4. **PRD & Spec Writing** — User personas, user stories, PRD, technical considerations
5. **Pitch Deck Creation** — Deck outline, content generation, interactive refinement
6. **Wireframe Generation** — Screen inventory, individual screen generation, flow connection

## Phase System

Projects progress through phases. Each phase suggests relevant workflows.

```
Ideation → Research → Sizing → Scoping → Documentation → Presentation
```

Phases are suggestions, not gates — you can jump around freely.

## Auto-Managed Context

The `.unshell/CLAUDE.md` file is what makes Unshell fundamentally different from using Claude in a browser. Instead of manually writing CLAUDE.md every time, Unshell maintains it automatically — tracking decisions, active documents, open questions, assumptions, and phase transitions.

## Architecture

| Component | Technology |
| --------- | ---------- |
| **Shell** | Electron desktop application |
| **Frontend** | React (three-panel layout) |
| **Editor** | TipTap (ProseMirror-based) |
| **Intelligence** | Claude Code via ACP |
| **Storage** | Plain filesystem (no database) |
| **File Watching** | chokidar |
| **Workflow Engine** | JSON-defined state machine |
| **Cost** | $0 API fees (uses existing Claude subscription) |

## Design Principles

1. **Files are the source of truth.** Everything is markdown/HTML on disk. No proprietary format. No lock-in.
2. **Claude is the engine, not the product.** The UI makes Claude Code's capabilities accessible — it doesn't rebuild them.
3. **Opinionated workflows beat flexible tools.** Structured pipelines save you from staring at a blank page.
4. **Context is everything.** Auto-managed `.unshell/CLAUDE.md` is the most important technical feature.
5. **Start rough, refine later.** HTML wireframes won't look like Figma. Markdown decks won't look like Keynote. The value is speed of iteration with Claude.
6. **One project, one folder, one workspace.** No cross-project features. No sharing. No collaboration. One human + one AI + one product idea.

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

| Command             | Description                   |
| ------------------- | ----------------------------- |
| `just init`         | Initialize direnv environment |
| `just deps`         | Install all dependencies      |
| `just server`       | Start development server      |
| `just build`        | Build for production          |
| `just format`       | Format code with Prettier     |
| `just format-check` | Check code formatting         |
| `just lint`         | Fix linting issues            |
| `just lint-check`   | Check for linting issues      |
| `just test`         | Run tests                     |

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

| Alias           | Path                        |
| --------------- | --------------------------- |
| `@/*`           | `src/renderer/*`            |
| `@components/*` | `src/renderer/components/*` |
| `@hooks/*`      | `src/renderer/hooks/*`      |
| `@stores/*`     | `src/renderer/stores/*`     |
| `@utils/*`      | `src/renderer/utils/*`      |
