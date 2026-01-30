# Hook Template

Use this template to configure lifecycle hooks in `.claude/settings.json`.

## Hook Events Reference

| Event | When It Fires | Can Block? | Common Use |
|-------|---------------|------------|------------|
| `PreToolUse` | Before any tool executes | Yes (exit 2) | Validation, guardrails |
| `PostToolUse` | After tool completes | No | Formatting, logging |
| `PermissionRequest` | When permission dialog shows | Yes | Auto-approve/deny |
| `UserPromptSubmit` | When user submits input | Yes | Logging, preprocessing |
| `Stop` | When Claude finishes responding | No | Cleanup, notifications |
| `SubagentStop` | When subagent stops | Yes (exit 2) | Result validation |
| `Notification` | When Claude sends notifications | No | External integrations |
| `SessionStart` | When session begins | No | Initialization |
| `PreCompact` | Before context compaction | No | State preservation |

## Exit Codes

| Code | Meaning | Effect |
|------|---------|--------|
| `0` | Success | Continue normally |
| `1` | Error | Show message to user, continue |
| `2` | Block | Prevent the action (PreToolUse, PermissionRequest, SubagentStop only) |

## Configuration Structure

```json
{
  "hooks": {
    "<EventName>": [
      {
        "matcher": "<ToolPattern>",
        "hooks": [
          {
            "type": "command",
            "command": "<shell command>",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

## Matcher Patterns

| Pattern | Matches |
|---------|---------|
| `Bash` | All bash commands |
| `Bash(npm:*)` | npm commands only |
| `Bash(rm:*)` | rm commands only |
| `Write` | File creation |
| `Edit` | File modification |
| `Write\|Edit` | Either write or edit |
| `Read` | File reading |
| `Task` | Subagent invocation |

## Environment Variables

Available in hook commands:

| Variable | Content |
|----------|---------|
| `$CLAUDE_PROJECT_DIR` | Project root directory |
| `$CLAUDE_FILE_PATHS` | Space-separated affected file paths |
| `$CLAUDE_NOTIFICATION` | Notification content (Notification event) |
| `$CLAUDE_TOOL_OUTPUT` | Tool output (PostToolUse only) |

## Common Hook Patterns

### Auto-Format on Save
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "prettier --write $CLAUDE_FILE_PATHS 2>/dev/null || true",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

### Lint After Modification
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "eslint $CLAUDE_FILE_PATHS --fix 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

### Block Dangerous Commands
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "echo \"$CLAUDE_TOOL_INPUT\" | grep -qE '(rm -rf|sudo|DROP TABLE)' && exit 2 || exit 0"
          }
        ]
      }
    ]
  }
}
```

### Log All Operations
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "echo \"$(date): Tool used on $CLAUDE_FILE_PATHS\" >> .claude/audit.log"
          }
        ]
      }
    ]
  }
}
```

### Type Check TypeScript
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "echo $CLAUDE_FILE_PATHS | grep -q '\\.ts' && npx tsc --noEmit || true",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### Session Initialization
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Session started' >> .claude/sessions.log"
          }
        ]
      }
    ]
  }
}
```

### Input Modification (v2.0.10+)
PreToolUse hooks can modify tool inputs before execution:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "echo '{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"decision\":{\"behavior\":\"allow\",\"updatedInput\":{\"command\":\"modified-command\"}}}}'"
          }
        ]
      }
    ]
  }
}
```

## Full Settings.json Example

```json
{
  "permissions": {
    "allow": [
      "Read(src/**)",
      "Write(src/**)",
      "Edit(src/**)",
      "Bash(npm:*)",
      "Bash(git:*)"
    ],
    "deny": [
      "Bash(rm -rf:*)",
      "Bash(sudo:*)",
      "Read(.env*)"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "prettier --write $CLAUDE_FILE_PATHS 2>/dev/null || true"
          },
          {
            "type": "command", 
            "command": "eslint $CLAUDE_FILE_PATHS --fix 2>/dev/null || true"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "echo \"$CLAUDE_TOOL_INPUT\" | grep -qiE 'production|prod' && echo 'WARNING: Production command detected' && exit 2 || exit 0"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "mkdir -p .claude && date >> .claude/sessions.log"
          }
        ]
      }
    ]
  }
}
```

## Optimization Tips

1. **Keep hooks fast** - Use timeout and avoid blocking operations
2. **Fail gracefully** - Use `|| true` for non-critical hooks
3. **Be specific with matchers** - Don't run hooks unnecessarily
4. **Test hooks locally** - Verify commands work before adding
5. **Log sparingly** - Don't create massive log files
