# Skill Template

Use this template to create skills in `.claude/skills/` or `~/.claude/skills/`.

## Key Concept

Skills are **model-invoked** - Claude automatically uses them when relevant.
Commands are **user-invoked** - you explicitly type `/command`.

Choose skill when: Claude should automatically apply this knowledge
Choose command when: User should explicitly trigger this action

## File Structure

```
.claude/skills/
└── <skill-name>/
    ├── SKILL.md          (required - main instructions)
    ├── scripts/          (optional - helper scripts)
    ├── templates/        (optional - boilerplate files)
    └── references/       (optional - documentation)
```

## SKILL.md Template

```markdown
---
name: [lowercase-with-hyphens, max 64 chars]
description: [WHAT it does AND WHEN to use it, max 1024 chars - THIS IS CRITICAL]
---

# [Skill Name]

## When to Use This Skill
[Explicit trigger conditions - be specific about context]

- When user asks about [topic]
- When working with files matching [pattern]
- When [specific situation]

## Instructions

### [Section 1]
[Clear, actionable instructions]

### [Section 2]
[Continue as needed]

## Patterns

### Pattern: [Name]
```[language]
[Code example]
```

### Anti-Pattern: [Name]
```[language]
[What NOT to do]
```
Why: [Explanation]

## References
- [Link or file reference]
- See also: [related skill or doc]
```

## Description Best Practices

The `description` field determines when Claude uses this skill. Make it count:

❌ Bad: "Helps with database stuff"
✅ Good: "PostgreSQL query optimization. Use when writing complex queries, debugging slow queries, or designing database schemas with PostgreSQL."

❌ Bad: "Code review helper"
✅ Good: "Security-focused code review for Node.js. Use when reviewing authentication, input validation, or API endpoint code."

### Description Formula
```
[What it does] + [specific technology/domain] + "Use when" + [trigger conditions]
```

## Optimization Checklist

- [ ] Name: lowercase, hyphens, ≤64 chars
- [ ] Description: includes WHEN to use, ≤1024 chars
- [ ] Trigger conditions explicitly listed
- [ ] Instructions use imperative voice
- [ ] Patterns include anti-patterns with reasoning
- [ ] File size reasonable (Claude reads entire skill)

## Examples

### Technical Skill
```markdown
---
name: react-performance
description: React performance optimization patterns. Use when analyzing slow renders, implementing memoization, debugging re-renders, or optimizing component hierarchies.
---

# React Performance Optimization

## When to Use
- Component renders slowly
- useEffect runs excessively
- Large lists cause lag
- State updates trigger cascading re-renders

## Patterns

### Memoization
```tsx
// Expensive computation
const result = useMemo(() => expensiveCalc(data), [data]);

// Stable callback
const handler = useCallback((e) => process(e), []);

// Component memoization
const Item = memo(({ data }) => <div>{data}</div>);
```

### Anti-Pattern: Inline Objects
```tsx
// ❌ Creates new object every render
<Child style={{ color: 'red' }} />

// ✅ Stable reference
const style = useMemo(() => ({ color: 'red' }), []);
<Child style={style} />
```
Why: Inline objects break referential equality, defeating memo().
```

### Process Skill
```markdown
---
name: pr-review-checklist
description: Pull request review process. Use when reviewing PRs, preparing code for review, or checking review completeness.
---

# PR Review Checklist

## When to Use
- Before approving any PR
- When preparing your own PR for review
- When review feedback seems incomplete

## Review Process

### 1. Understand Context
- Read PR description and linked issues
- Check branch name for intent
- Review commit history for logical progression

### 2. Code Quality
- [ ] No commented-out code
- [ ] No debug statements (console.log, debugger)
- [ ] No hardcoded secrets or credentials
- [ ] Error handling for edge cases

### 3. Testing
- [ ] Tests cover happy path
- [ ] Tests cover error cases
- [ ] Tests cover edge cases
- [ ] No flaky test patterns

### 4. Security (if applicable)
- [ ] Input validation present
- [ ] SQL injection prevented
- [ ] XSS prevented
- [ ] Auth/authz checked
```

### Domain Knowledge Skill
```markdown
---
name: elixir-otp-patterns
description: Elixir OTP supervision and GenServer patterns. Use when designing supervision trees, implementing GenServers, handling process failures, or building fault-tolerant systems.
---

# Elixir OTP Patterns

## When to Use
- Designing new supervision trees
- Implementing GenServer processes
- Handling process crashes gracefully
- Building distributed systems in Elixir

## Supervision Strategies

### one_for_one
Use when: Children are independent
```elixir
children = [
  {Worker1, []},
  {Worker2, []}
]
Supervisor.start_link(children, strategy: :one_for_one)
```

### one_for_all
Use when: Children are interdependent
```elixir
# If one fails, restart all
Supervisor.start_link(children, strategy: :one_for_all)
```

### rest_for_one
Use when: Later children depend on earlier ones
```elixir
# If one fails, restart it and all children started after it
Supervisor.start_link(children, strategy: :rest_for_one)
```

## GenServer Patterns

### Call vs Cast
- `call` - Synchronous, caller waits for response
- `cast` - Asynchronous, fire-and-forget

### Anti-Pattern: Blocking in init/1
```elixir
# ❌ Blocks supervisor startup
def init(_) do
  data = slow_database_call()  # BAD
  {:ok, data}
end

# ✅ Defer heavy work
def init(_) do
  send(self(), :initialize)
  {:ok, %{}}
end

def handle_info(:initialize, state) do
  data = slow_database_call()
  {:noreply, %{state | data: data}}
end
```
Why: Blocking init/1 can cause supervisor startup timeouts.
```
