# Workflow Documentation Template

This template is **critical** for the Update workflow functionality. Every workflow must have documentation following this structure so updates can be applied correctly.

## File Location

```
docs/claude-code/<workflow-name>-workflow.md
```

## Template Structure

```markdown
# [Workflow Name] Workflow

> [One-line description of what this workflow does]

**Created:** [YYYY-MM-DD]  
**Last Updated:** [YYYY-MM-DD]  
**Version:** [X.Y.Z]

## Overview

[2-3 sentence description of the workflow's purpose and primary use case]

## Artifact Inventory

### Commands
| Command | Path | Description |
|---------|------|-------------|
| `/[name]` | `.claude/commands/[path]` | [Brief description] |

### Skills
| Skill | Path | Description |
|-------|------|-------------|
| [name] | `.claude/skills/[name]/SKILL.md` | [Brief description] |

### Agents
| Agent | Path | Description |
|-------|------|-------------|
| [name] | `.claude/agents/[name].md` | [Brief description] |

### Hooks
| Event | Purpose |
|-------|---------|
| [Event] | [What it does] |

### Configuration
| File | Purpose |
|------|---------|
| [path] | [What it configures] |

## Architecture

### Flow Diagram
```
[User Input]
     │
     ▼
┌─────────────┐
│ [Step 1]    │
└─────────────┘
     │
     ▼
┌─────────────┐
│ [Step 2]    │
└─────────────┘
     │
     ▼
[Output]
```

### Component Interactions
[Describe how artifacts work together]

## Usage

### Basic Usage
```bash
[Primary command with example]
```

### Examples

#### Example 1: [Scenario Name]
```bash
[Command]
```
Expected output:
```
[What user should see]
```

#### Example 2: [Scenario Name]
```bash
[Command]
```

### Options/Arguments
| Argument | Required | Description |
|----------|----------|-------------|
| [arg] | Yes/No | [What it does] |

## Configuration

### Required Setup
1. [Setup step 1]
2. [Setup step 2]

### Optional Configuration
[Any optional settings]

### Environment Variables
| Variable | Purpose | Default |
|----------|---------|---------|
| [VAR] | [Purpose] | [Default or required] |

## Customization

### Extending the Workflow
[How to add functionality]

### Modifying Behavior
[How to change existing behavior]

## Troubleshooting

### Common Issues

#### Issue: [Problem description]
**Cause:** [Why it happens]  
**Solution:** [How to fix]

#### Issue: [Problem description]
**Cause:** [Why it happens]  
**Solution:** [How to fix]

### Debug Mode
[How to enable verbose output or debugging]

## Changelog

### [X.Y.Z] - YYYY-MM-DD
- [Change 1]
- [Change 2]

### [X.Y.Z-1] - YYYY-MM-DD
- [Previous changes]

## Related Workflows
- [Link to related workflow 1]
- [Link to related workflow 2]
```

## Why This Structure Matters

The Update workflow parses this documentation to:

1. **Find artifacts** - Artifact Inventory provides exact paths
2. **Understand relationships** - Architecture section shows dependencies
3. **Apply changes safely** - Component interactions prevent breaking changes
4. **Track history** - Changelog shows what changed and when

## Required Sections for Update

These sections are **required** for update functionality:

- [ ] Artifact Inventory (with exact paths)
- [ ] Architecture (flow diagram)
- [ ] Changelog (version history)

## Example: Complete Workflow Doc

```markdown
# Code Review Workflow

> Automated code review with security, performance, and quality analysis.

**Created:** 2025-01-15  
**Last Updated:** 2025-01-20  
**Version:** 1.2.0

## Overview

This workflow automates comprehensive code review by running security scans, performance analysis, and code quality checks. Results are compiled into a formatted report.

## Artifact Inventory

### Commands
| Command | Path | Description |
|---------|------|-------------|
| `/review` | `.claude/commands/review.md` | Main entry point |
| `/review:security` | `.claude/commands/review/security.md` | Security-only review |

### Skills
| Skill | Path | Description |
|-------|------|-------------|
| code-patterns | `.claude/skills/code-patterns/SKILL.md` | Pattern detection |

### Agents
| Agent | Path | Description |
|-------|------|-------------|
| security-auditor | `.claude/agents/security-auditor.md` | Security analysis |
| perf-analyzer | `.claude/agents/perf-analyzer.md` | Performance analysis |

### Hooks
| Event | Purpose |
|-------|---------|
| PostToolUse (Edit) | Auto-format after changes |

### Configuration
| File | Purpose |
|------|---------|
| `.claude/settings.json` | Hook configuration |

## Architecture

### Flow Diagram
```
[/review command]
        │
        ▼
┌───────────────────┐
│ Parse Arguments   │
│ (file or PR)      │
└───────────────────┘
        │
        ├─────────────────┬─────────────────┐
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Security     │  │ Performance  │  │ Quality      │
│ Auditor      │  │ Analyzer     │  │ Check        │
│ (subagent)   │  │ (subagent)   │  │ (main)       │
└──────────────┘  └──────────────┘  └──────────────┘
        │                 │                 │
        └─────────────────┴─────────────────┘
                          │
                          ▼
                ┌───────────────────┐
                │ Compile Report    │
                └───────────────────┘
                          │
                          ▼
                    [Markdown Report]
```

### Component Interactions
- Main command dispatches to subagents in parallel
- Each subagent has isolated context
- Results aggregated into single report
- Hooks auto-format any suggested fixes

## Usage

### Basic Usage
```bash
/review src/api/auth.ts
```

### Examples

#### Example 1: Review Single File
```bash
/review src/services/payment.ts
```
Expected output:
```markdown
## Code Review: payment.ts

### Security: ✅ No Issues
### Performance: ⚠️ 2 Warnings
- Line 45: N+1 query in loop
- Line 89: Unbounded array growth

### Quality: ✅ Good
```

#### Example 2: Review Directory
```bash
/review src/api/
```

### Options/Arguments
| Argument | Required | Description |
|----------|----------|-------------|
| path | Yes | File or directory to review |
| --security-only | No | Skip performance/quality |
| --verbose | No | Show detailed analysis |

## Configuration

### Required Setup
1. Ensure `.claude/agents/` contains security-auditor.md and perf-analyzer.md
2. Configure hooks in `.claude/settings.json`

### Optional Configuration
Add to `.claude/settings.json`:
```json
{
  "review": {
    "securityLevel": "strict",
    "performanceThreshold": "medium"
  }
}
```

## Troubleshooting

### Common Issues

#### Issue: Subagent timeout
**Cause:** Large files take longer to analyze  
**Solution:** Split review into smaller chunks

#### Issue: Missing security patterns
**Cause:** Security skill not loaded  
**Solution:** Ensure `code-patterns` skill exists

## Changelog

### [1.2.0] - 2025-01-20
- Added parallel subagent execution
- Improved report formatting

### [1.1.0] - 2025-01-18
- Added performance analyzer subagent
- Fixed security false positives

### [1.0.0] - 2025-01-15
- Initial release

## Related Workflows
- [Test Generation Workflow](./test-generation-workflow.md)
- [Documentation Workflow](./documentation-workflow.md)
```

## Validation Checklist

Before considering workflow documentation complete:

- [ ] All artifacts have exact paths
- [ ] Flow diagram shows complete process
- [ ] At least 2 usage examples
- [ ] Troubleshooting includes common issues
- [ ] Changelog has at least initial version
- [ ] Related workflows linked if applicable
