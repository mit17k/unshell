# Workflow Factory Workflow

> Meta-tooling that creates and updates Claude Code workflows with optimized artifacts.

**Created:** 2025-01-27  
**Last Updated:** 2025-01-27  
**Version:** 1.0.0

## Overview

The Workflow Factory is a self-contained system for creating complete Claude Code workflows. It includes templates for all artifact types, optimization patterns, and generates comprehensive documentation that enables future updates.

## Artifact Inventory

### Commands
| Command | Path | Description |
|---------|------|-------------|
| `/claude:workflow` | `.claude/commands/claude/workflow.md` | Main entry point for create/update |

### Skills
| Skill | Path | Description |
|-------|------|-------------|
| workflow-optimization | `.claude/skills/workflow-optimization/SKILL.md` | Optimization patterns and validation |

### Templates
| Template | Path | Purpose |
|----------|------|---------|
| Command | `.claude/templates/command.template.md` | Slash command structure |
| Skill | `.claude/templates/skill.template.md` | Model-invoked skill structure |
| Agent | `.claude/templates/agent.template.md` | Subagent structure |
| Hook | `.claude/templates/hook.template.md` | Lifecycle hook configuration |
| CLAUDE.md | `.claude/templates/claude-md.template.md` | Project memory structure |
| Workflow Doc | `.claude/templates/workflow-doc.template.md` | Documentation structure |

### Configuration
| File | Purpose |
|------|---------|
| `CLAUDE.md` | Project memory with quick reference |

## Architecture

### CREATE Flow
```
[/claude:workflow Create <name>. <description>]
                    │
                    ▼
        ┌───────────────────────┐
        │ Parse Arguments       │
        │ Extract: name, desc   │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ Read All Templates    │
        │ .claude/templates/*   │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ Design Architecture   │
        │ Determine artifacts   │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ Generate Artifacts    │
        │ Apply optimization    │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ Create Documentation  │
        │ docs/claude-code/     │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ Validate & Report     │
        └───────────────────────┘
```

### UPDATE Flow
```
[/claude:workflow Update <doc-path>. <changes>]
                    │
                    ▼
        ┌───────────────────────┐
        │ Read Workflow Doc     │
        │ Parse artifact list   │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ Analyze Changes       │
        │ Map to artifacts      │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ Apply Modifications   │
        │ Update each artifact  │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ Update Documentation  │
        │ Add changelog entry   │
        └───────────────────────┘
```

### Component Interactions
- Main command reads templates for structure guidance
- Optimization skill provides validation rules
- Templates ensure consistent artifact format
- Workflow doc enables update functionality

## Usage

### Basic Usage: Create
```bash
/claude:workflow Create code-review. Automated code review workflow with security scanning, performance analysis, and quality checks. Should use subagents for parallel analysis.
```

### Basic Usage: Update
```bash
/claude:workflow Update docs/claude-code/code-review-workflow.md. Add static analysis step using ESLint and add hook to auto-format suggested fixes.
```

### Examples

#### Example 1: Create Test Generation Workflow
```bash
/claude:workflow Create test-gen. TDD workflow that generates tests before implementation, runs them to verify failure, then generates implementation code. Should follow red-green-refactor pattern.
```

Expected artifacts:
- `/test:generate` command
- `/test:verify` command  
- `tdd-patterns` skill
- `test-generator` agent
- Workflow documentation

#### Example 2: Create Documentation Workflow
```bash
/claude:workflow Create docs. Automated documentation generation for code. Generates JSDoc/docstrings, README updates, and API documentation. Should analyze existing docs for consistency.
```

#### Example 3: Update Existing Workflow
```bash
/claude:workflow Update docs/claude-code/test-gen-workflow.md. Add coverage checking step that fails if coverage drops below 80%. Also add a hook to run tests after any code modification.
```

### Options/Arguments
| Argument | Required | Description |
|----------|----------|-------------|
| Action | Yes | `Create` or `Update` |
| Target | Yes | Workflow name (Create) or doc path (Update) |
| Description | Yes | Detailed instructions after the period |

## Configuration

### Required Setup
1. Ensure `.claude/templates/` directory exists with all templates
2. Ensure `.claude/skills/workflow-optimization/` skill is present
3. Ensure `docs/claude-code/` directory exists

### Directory Structure
```
project/
├── .claude/
│   ├── commands/
│   │   └── claude/
│   │       └── workflow.md
│   ├── skills/
│   │   └── workflow-optimization/
│   │       └── SKILL.md
│   └── templates/
│       ├── command.template.md
│       ├── skill.template.md
│       ├── agent.template.md
│       ├── hook.template.md
│       ├── claude-md.template.md
│       └── workflow-doc.template.md
├── docs/
│   └── claude-code/
│       └── [workflow]-workflow.md
└── CLAUDE.md
```

## Customization

### Adding New Template Types
1. Create template in `.claude/templates/[type].template.md`
2. Update workflow command to recognize new type
3. Add validation rules to optimization skill
4. Update this documentation

### Modifying Optimization Rules
Edit `.claude/skills/workflow-optimization/SKILL.md`:
- Token budgets in "Minimal Signal Principle" section
- Validation checklists at the end
- Anti-patterns list

## Troubleshooting

### Common Issues

#### Issue: "Template not found"
**Cause:** Missing template file in `.claude/templates/`  
**Solution:** Ensure all template files exist. Run:
```bash
ls .claude/templates/
```

#### Issue: "Cannot update workflow"
**Cause:** Workflow documentation missing or malformed  
**Solution:** Ensure `docs/claude-code/<n>-workflow.md` exists and has Artifact Inventory section

#### Issue: "Generated artifacts don't work"
**Cause:** Optimization rules too aggressive or templates outdated  
**Solution:** Review generated artifacts, check against templates, adjust as needed

### Debug Mode
Add `--verbose` or ask for detailed output:
```bash
/claude:workflow Create test-flow. [description]. Show detailed reasoning for each decision.
```

## Changelog

### [1.0.0] - 2025-01-27
- Initial release
- CREATE and UPDATE workflows implemented
- Templates for all artifact types
- Optimization skill with validation rules
- Self-documenting (this document)

## Related Workflows
- This is the root workflow - it creates other workflows
- Generated workflows will appear in `docs/claude-code/`

---

## Meta-Notes

This workflow is self-referential: it documents itself and can theoretically update itself. The circular nature is intentional - it demonstrates that the system works and provides a concrete example of proper workflow documentation.
