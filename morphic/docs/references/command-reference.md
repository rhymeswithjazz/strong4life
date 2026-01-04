# Command Reference - Strong4Life

Quick reference for all morphic commands.

## Core System

| Command | Purpose | Usage |
|---------|---------|-------|
| /prime-agent | Restore context after crash or fresh start | `/prime-agent` |
| /cleanup | Maintain internal consistency | `/cleanup` or `/cleanup mode=report-only` |
| /evolve | Self-improvement and system optimization | `/evolve` or `/evolve aggressiveness=conservative` |
| /abstract | Convert manual tasks to reusable commands | `/abstract` |

## Development Lifecycle

| Command | Purpose | Usage |
|---------|---------|-------|
| /build-feature | Implement feature from user story | `/build-feature story="Add workout timer"` |
| /run-tests | Execute comprehensive test suite | `/run-tests` or `/run-tests but skip e2e` |
| /code-review | Perform quality and security review | `/code-review` or `/code-review focus=security` |
| /ship-feature | Complete end-to-end feature delivery | `/ship-feature` |
| /push-all | Stage, commit, and push all changes | `/push-all` (use with caution) |

## Code Quality & Maintenance

| Command | Purpose | Usage |
|---------|---------|-------|
| /debug | Systematic debugging workflow | `/debug issue="Session timeout error"` |
| /refactor | Safe code improvement with tests | `/refactor target=WorkoutsContext goal=simplify` |
| /update-deps | Smart dependency management | `/update-deps type=minor` |

## Infrastructure & DevOps

| Command | Purpose | Usage |
|---------|---------|-------|
| /setup-ci-cd | Configure robust CI/CD pipeline | `/setup-ci-cd` |
| /deploy | Deploy to environments with safety checks | `/deploy environment=staging` |

## System Management

| Command | Purpose | Usage |
|---------|---------|-------|
| /init-morphic | Bootstrap morphic system | `/init-morphic` (run once) |

## Tips

### Morphing Commands
Most commands can be morphed inline with natural language:
```
/run-tests but skip e2e tests and focus on LiveView tests
/code-review focus=security thoroughness=10
/deploy environment=staging skip=smoke-tests
/build-feature story="..." but use TDD approach
```

### Chaining Workflows
Commands naturally chain together for complete workflows:
```
/build-feature → /run-tests → /code-review → /ship-feature
```

Or execute them individually:
```bash
/build-feature story="Add workout notes field"
# ... review generated code ...
/run-tests
# ... fix any failures ...
/code-review
# ... address feedback ...
/ship-feature
```

### Getting Help
- Read command files in `morphic/commands/` for detailed documentation
- Use `/prime-agent` to restore context if lost
- Run `/cleanup` if system feels inconsistent
- Check `morphic/AGENT.md` for agent behavior details

### Context-Specific Usage

**For authentication-related work:**
- Always remember: Use `@current_scope.user`, never `@current_user`
- Pass `current_scope` as first argument to all context functions

**For LiveView development:**
- Use streams for lists: `stream/3` and `stream_insert/3`
- Mobile-first: Minimum 44px touch targets
- No inline scripts: Use hooks in `assets/js/`

**For database changes:**
- WorkoutSession uses `:binary_id` (UUIDs)
- User uses standard integer IDs
- Seeds are idempotent - safe to re-run

---

**Last Updated**: 2026-01-03
