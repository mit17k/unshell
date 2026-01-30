# Command Template

Use this template to create slash commands for `.claude/commands/`.

## File Naming
- Location: `.claude/commands/<namespace>/<command>.md` or `.claude/commands/<command>.md`
- Namespace creates prefix: `.claude/commands/dev/test.md` → `/dev:test`
- Without namespace: `.claude/commands/build.md` → `/build`

## Template Structure

```markdown
---
allowed-tools: [REQUIRED: Comma-separated tool list]
argument-hint: [OPTIONAL: Shows in /help, e.g., "[file] [options]"]
description: [REQUIRED: One-line description for /help]
model: [OPTIONAL: Override model, e.g., "claude-3-5-haiku-20241022"]
---

# [Command Purpose - Brief Title]

[OPTIONAL: Context paragraph if complex command]

## Input
$ARGUMENTS contains: [describe expected input format]

## Process

### Step 1: [Name]
[Instructions - imperative voice]

### Step 2: [Name]
[Instructions]

[Continue as needed...]

## Output Format
[Specify exact output structure]

## Constraints
- [Constraint 1]
- [Constraint 2]

## Error Handling
- If [condition]: [action]
- If [condition]: [action]
```

## Allowed Tools Reference

| Pattern | Scope |
|---------|-------|
| `Read` | Read any file |
| `Read(src/**)` | Read only in src/ |
| `Write` | Create files |
| `Edit, MultiEdit` | Modify files |
| `Bash` | Full shell access |
| `Bash(npm:*)` | Only npm commands |
| `Bash(git add:*, git commit:*)` | Specific git commands |
| `Glob, Grep` | Search operations |
| `Task` | Spawn subagents |
| `WebFetch, WebSearch` | External resources |

## Argument Patterns

### Single Argument
```markdown
argument-hint: [filename]
---
Process the file: $ARGUMENTS
```

### Positional Arguments
```markdown
argument-hint: [source] [target] [options]
---
Source: $1
Target: $2
Options: $3
```

### Optional Arguments
```markdown
argument-hint: [file] [--verbose]
---
Check if verbose: `$ARGUMENTS` contains "--verbose"
```

## Optimization Checklist

- [ ] Description under 80 characters
- [ ] Allowed-tools minimally scoped (principle of least privilege)
- [ ] Critical instructions in first 3 lines of body
- [ ] Imperative voice throughout
- [ ] Specific file paths, not "the relevant files"
- [ ] Output format explicitly defined
- [ ] Error cases handled

## Examples

### Simple Read-Only Command
```markdown
---
allowed-tools: Read, Glob, Grep
argument-hint: [pattern]
description: Find and summarize files matching pattern
---

# File Summary

Find files matching `$ARGUMENTS` pattern.
List each file with: path, size, first 10 lines summary.
Output as markdown table.
```

### Code Generation Command
```markdown
---
allowed-tools: Read, Write, Edit, Bash(npm test:*)
argument-hint: [component-name]
description: Generate React component with tests
---

# Component Generator

## Input
Component name: $ARGUMENTS

## Process
1. Read `src/components/` for existing patterns
2. Generate component file: `src/components/$ARGUMENTS/$ARGUMENTS.tsx`
3. Generate test file: `src/components/$ARGUMENTS/$ARGUMENTS.test.tsx`
4. Run tests to verify

## Output
- Component path
- Test path
- Test results

## Constraints
- Follow existing component patterns exactly
- Use TypeScript strict mode
- Include prop types interface
```

### Dangerous Operations Command
```markdown
---
allowed-tools: Read, Bash(rm:*), Bash(git:*)
argument-hint: [branch-name]
description: Clean up merged branch and artifacts
---

# Branch Cleanup

## Input
Branch: $ARGUMENTS

## Process
1. Verify branch is merged into main
2. **STOP AND CONFIRM** before any deletion
3. Delete local branch
4. Delete remote branch
5. Clean build artifacts

## Safety
- NEVER delete main, master, or develop
- ALWAYS verify merge status first
- List all deletions before executing
```
