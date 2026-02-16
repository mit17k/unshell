# Unshell

**Cursor for Product Teams.**

[Cursor](https://cursor.com) revolutionized how developers work by embedding AI directly into their code editor — making the entire codebase an active collaborator rather than a passive file system. Unshell does the same thing for product teams.

Unshell is a desktop app that brings Claude's agentic workflows into a purpose-built GUI, turning product managers, designers, and analysts into AI-augmented operators. No terminal. No API keys. Just your existing Claude Pro or Max subscription and a workspace designed for how product teams actually think and work.

## The Problem

Developers have Cursor. They ship faster, explore codebases instantly, and automate tedious tasks with AI baked into every interaction.

Product teams have... chat windows. They copy-paste between Claude, Jira, Notion, and Figma. They context-switch constantly. The most powerful AI workflows live behind a terminal that most product people will never open.

**The gap isn't intelligence — it's interface.**

## How Unshell Solves It

Just as Cursor gives developers project-wide AI understanding across their codebase, Unshell gives product teams project-wide AI understanding across their product context.

| What Cursor does for developers        | What Unshell does for product teams      |
| --------------------------------------- | ---------------------------------------- |
| Understands your entire codebase        | Understands your entire product context  |
| Multi-file edits in one action          | Multi-tool workflows in one action       |
| AI embedded in the editor               | AI embedded in the product workspace     |
| Works with your existing AI models      | Works with your existing Claude subscription |
| Eliminates context-switching with tools | Eliminates context-switching across tools |

## Key Features

### Bring Your Own Subscription (BYOS)

Connects to local Claude credentials. No API keys, no per-token billing, no additional infrastructure. Usage runs against your existing monthly subscription quota.

### Workflow Orchestration

One-click Action Cards for common product tasks:

- **Spec-to-Ticket** — Turn a messy brainstorming doc into structured Jira stories
- **Roadmap Refiner** — Analyze feature requests against current product pillars
- **The "Roast" Protocol** — Get critical feedback on product logic or technical debt

### Full Product Context via MCP

Natively connects to your internal tools (GitHub, Jira, Notion, databases) via the Model Context Protocol. Claude always has the full picture — just like Cursor indexes your entire repo.

### Local-First Privacy

All processing happens on your machine. Internal data never touches a centralized server. Your product strategy stays yours.

## Architecture

| Component            | Technology                       |
| -------------------- | -------------------------------- |
| **Engine**           | Electron desktop application     |
| **Intelligence**     | Claude Agent SDK (local)         |
| **GUI-Agent Bridge** | Agent Client Protocol (ACP)      |
| **Data Connections** | Model Context Protocol (MCP)     |
| **Cost**             | $0 API fees (subscription-based) |

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
