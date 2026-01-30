# Unshell

**The Product Team's Command Center for Claude.**

Unshell is a specialized desktop interface designed to bring the raw power of Claude's agentic workflows out of the terminal and into a high-productivity GUI. Built specifically for product teams, Unshell eliminates the "CLI barrier," allowing non-technical stakeholders to execute complex, multi-step workflows—from spec drafting to Jira ticket generation—using their existing Claude Pro or Max subscriptions.

## Why Unshell?

While Claude Code provides incredible developer productivity, the terminal is a friction point for Product Managers. Unshell "unshells" that power, providing a polished, "Whiteboard Energy" interface that turns Claude into a specialized, always-on product partner.

## Key Features

### Bring Your Own Subscription (BYOS)
Seamlessly connects to local Claude credentials. No API keys, no per-token billing, and zero additional infrastructure costs. Usage is billed against users' existing monthly subscription quotas.

### Workflow Orchestration
One-click "Action Cards" for common product tasks:
- **Spec-to-Ticket**: Turns a messy brainstorming doc into a structured set of Jira stories
- **Roadmap Refiner**: Analyzes feature requests against current product pillars
- **The "Roast" Protocol**: Provides critical feedback on product logic or technical debt

### MCP Integration
Natively connects to internal company data (GitHub, Jira, Notion, or custom DBs) via the Model Context Protocol, ensuring Claude always has the full product context.

### Local-First Privacy
All processing happens on the user's machine. Internal data never touches a centralized LLM server you control.

## Technical Architecture

| Component | Technology |
|-----------|------------|
| **Engine** | Electron desktop application |
| **Intelligence** | Claude Agent SDK (local) |
| **GUI-Agent Bridge** | Agent Client Protocol (ACP) |
| **Data Connections** | Model Context Protocol (MCP) |
| **Cost** | $0 API fees (subscription-based) |

## Getting Started

Users perform a one-time `claude login` (triggered by the app), and then interact with "Action Cards" instead of complex terminal commands.

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
