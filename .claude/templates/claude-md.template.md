# CLAUDE.md Template

Use this template to create project memory files.

## File Locations

| Location | Scope | Git Status |
|----------|-------|------------|
| `./CLAUDE.md` | Project root, team-wide | Check into git |
| `./CLAUDE.local.md` | Project root, personal | .gitignore |
| `~/.claude/CLAUDE.md` | User-level, all projects | N/A |
| Child directories | On-demand loading | Check into git |

**Note:** `CLAUDE.local.md` goes at project ROOT, not inside `.claude/`.

## Sizing Guidelines

**Target: <1000 tokens (~4KB text)**

CLAUDE.md loads into EVERY conversation. Every line has a cost. Be ruthless.

### Token Budget
| Section | Budget | Priority |
|---------|--------|----------|
| Quick Reference | 200 tokens | Critical |
| Architecture | 300 tokens | High |
| Conventions | 300 tokens | Medium |
| Commands | 100 tokens | Medium |
| Warnings | 100 tokens | High |

## Template Structure

```markdown
# [Project Name]

[One-sentence description. What does this do?]

## Quick Reference

| Task | Command |
|------|---------|
| Dev server | `[command]` |
| Tests | `[command]` |
| Build | `[command]` |
| Lint | `[command]` |

## Architecture

[Brief description - 2-3 sentences max]

### Key Directories
```
src/
├── api/        # [purpose]
├── services/   # [purpose]
├── models/     # [purpose]
└── utils/      # [purpose]
```

### Key Files
- `src/index.ts` - Entry point
- `src/config.ts` - Configuration
- [other critical files]

## Conventions

### Code Style
- [Convention 1 - be specific]
- [Convention 2]
- [Convention 3]

### Patterns
[Pattern name]: [Brief description or file reference]

## ⚠️ Warnings

- [Critical gotcha 1]
- [Critical gotcha 2]
- [Non-obvious behavior]

## External Docs
- [Link to detailed docs if needed]
- [API reference]
```

## Content Prioritization

### Include (High Value)
✅ Project-specific conventions Claude can't infer
✅ Non-obvious architectural decisions
✅ Critical gotchas and warnings
✅ Commonly used commands
✅ Key file locations

### Exclude (Low Value)
❌ Standard language features (Claude knows these)
❌ Framework documentation (Claude knows these)
❌ Obvious patterns (if it's in the code, Claude can read it)
❌ Historical decisions (unless they affect current behavior)
❌ Aspirational guidelines (document reality, not wishes)

## Optimization Checklist

Every line must pass these tests:

1. **Inference Test**: Can Claude figure this out from the code?
   - If yes → remove it
   
2. **Behavior Test**: Does this change Claude's behavior?
   - If no → remove it
   
3. **Specificity Test**: Is this project-specific?
   - If no → remove it

4. **Staleness Test**: Will this become outdated?
   - If yes → reference external doc instead

## Anti-Patterns

### ❌ Generic Boilerplate
```markdown
## Testing
We use Jest for testing. Write good tests.
```

### ✅ Specific Guidance
```markdown
## Testing
- Use fixtures from `tests/fixtures/`
- Mock external APIs with `tests/mocks/api.ts`
- Database tests use `tests/setup/db.ts` for isolation
```

### ❌ Obvious Information
```markdown
## TypeScript
Use TypeScript for all new files. Follow TypeScript best practices.
```

### ✅ Non-Obvious Information
```markdown
## TypeScript
- Enable `strict: true` in all packages
- Use `type` over `interface` for object shapes
- Zod schemas in `src/schemas/` define runtime types
```

### ❌ Aspirational Documentation
```markdown
## Architecture
We're moving toward a microservices architecture with event sourcing.
```

### ✅ Current Reality
```markdown
## Architecture
Monolith with service layer. Database is source of truth.
Migration in progress - some services emit events (see src/events/).
```

## Examples

### Minimal CLAUDE.md (Simple Project)
```markdown
# todo-api

Express REST API for todo management.

## Commands
| Task | Command |
|------|---------|
| Dev | `npm run dev` |
| Test | `npm test` |

## Structure
- `src/routes/` - API endpoints
- `src/models/` - Sequelize models
- `src/middleware/` - Auth, validation

## Conventions
- Controllers return `{ success, data, error }`
- Use `src/utils/errors.ts` for error types
- Auth via JWT in Authorization header

## ⚠️ Warnings
- Never call `model.destroy()` - use soft delete
- Rate limiting on `/api/auth/*` routes
```

### Comprehensive CLAUDE.md (Complex Project)
```markdown
# atlas-platform

Elixir/Phoenix API with React admin dashboard.

## Quick Reference
| Task | Command |
|------|---------|
| API server | `mix phx.server` |
| Tests | `mix test` |
| Migrations | `mix ecto.migrate` |
| Dashboard | `cd admin && npm start` |

## Architecture

Phoenix umbrella app with 3 main applications:
- `atlas_core` - Business logic, Ecto schemas
- `atlas_api` - REST/GraphQL endpoints  
- `atlas_workers` - Background job processing

### Key Paths
```
apps/
├── atlas_core/lib/
│   ├── accounts/    # User management
│   ├── billing/     # Stripe integration
│   └── content/     # CMS functionality
├── atlas_api/lib/
│   └── controllers/ # API endpoints
└── atlas_workers/lib/
    └── jobs/        # Oban workers
```

## Conventions

### Elixir
- Contexts expose public API only
- Use changesets for all data mutations
- Pattern match in function heads, not case statements

### Database
- Soft deletes via `deleted_at` timestamp
- UUIDs for all primary keys
- Indexes defined in migrations, not schemas

### API
- REST endpoints in `/api/v1/*`
- GraphQL at `/graphql`
- Auth via Bearer token (see `atlas_api/plugs/auth.ex`)

## ⚠️ Warnings

- **Billing**: Test with Stripe test keys only (`STRIPE_SECRET_KEY`)
- **Workers**: Oban jobs are idempotent - may retry
- **Cache**: Redis cache invalidation is manual (see `atlas_core/cache.ex`)

## Detailed Docs
- API specs: `docs/api/openapi.yaml`
- Architecture: `docs/ARCHITECTURE.md`
```

## Modular Approach

For large projects, keep CLAUDE.md lean and reference detailed docs:

```markdown
# big-project

Enterprise platform. See docs/ for details.

## Quick Reference
[Essential commands only]

## Architecture
→ See `docs/ARCHITECTURE.md`

## API
→ See `docs/api/README.md`

## Conventions
→ See `docs/CONVENTIONS.md`

## ⚠️ Critical Warnings
[Only the most critical gotchas here]
```
