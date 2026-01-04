# Agent Instructions - Strong4Life

Instructions for the AI agent working in this morphic programming system.

## Your Role

You are an AI agent operating within a morphic programming system. Your primary responsibilities:

1. **Execute commands** defined in the `commands/` directory
2. **Maintain consistency** across the system
3. **Learn and improve** through the `/evolve` and `/abstract` commands
4. **Track progress** in `progress/progress_log.md`
5. **Follow morphic principles** in all operations

## Core Principles

### 1. Morphability
Commands can be morphed inline with natural language:
```
/run-tests but skip e2e and focus on unit tests
/code-review focus=security thoroughness=10
```

### 2. Reproducibility
Always maintain state so the system can be restored:
- Update `progress_log.md` after significant work
- Keep `current_tasks.md` current
- Create detailed commit messages

### 3. Internal Consistency
Before completing work:
- Run `/cleanup` to verify consistency
- Ensure all references are valid
- Update documentation as needed

## Command Execution

### Standard Workflow
1. **Understand** - Read the command fully
2. **Plan** - Create execution plan if complex
3. **Execute** - Follow the steps precisely
4. **Verify** - Check results
5. **Document** - Update progress log
6. **Clean** - Run cleanup if significant changes

### Error Handling
- If a command fails, analyze why
- Provide clear error messages
- Suggest corrections
- Don't silently fail

## Context Management

### Always Read on Prime
When `/prime-agent` is invoked, read:
1. `README.md` - Project overview
2. `AGENT.md` - This file
3. `progress/progress_log.md` - Recent history (last 20 entries)
4. `progress/current_tasks.md` - Active work
5. `context/system/` - System-wide context
6. Git status and recent commits
7. `/Users/ras/Projects/strong4life/CLAUDE.md` - Project-specific instructions

### Context Layers

**System-Wide Context** (always relevant):
- Project architecture and patterns
- Coding standards and style guides
- Team conventions
- Infrastructure setup

**Activity-Specific Context** (loaded as needed):
- Feature specifications
- Bug reports
- Performance requirements
- Design documents

## Code Quality Standards

### Follow CLAUDE.md Standards
This project has comprehensive CLAUDE.md files with specific standards:

**From Global CLAUDE.md** (`~/.claude/CLAUDE.md`):
- **Functional programming first** - Pure functions, immutable data
- **Data mutation exceptions** - Only when absolutely necessary
- **Composition over inheritance**
- **Declarative over imperative**

**From Project CLAUDE.md** (`/Users/ras/Projects/strong4life/CLAUDE.md`):
- **Scope-based authentication** - Always use `@current_scope.user`, never `@current_user`
- **Mobile-first design** - This is a gym app
- **LiveView patterns** - Streams over assigns, no inline scripts
- **Context-based architecture** - Accounts and Workouts contexts
- **Use Req library** - Not httpoison/tesla/httpc

### Strong4Life-Specific Patterns

**Authentication:**
- Always pass `current_scope` as first argument to context functions
- User ID filtering happens in context layer via `current_scope.user.id`
- Pass `current_scope={@current_scope}` when using `<Layouts.app>`

**LiveView:**
- Use `stream/3` for workout sets and history lists
- Provide `phx-update="stream"` with unique DOM IDs
- Re-stream items with `stream_insert/3` when updating

**Database:**
- Binary UUIDs for WorkoutSession and related tables
- Integer IDs for User table
- Idempotent seeds - safe to re-run

## Progress Tracking

### Update Progress Log
After completing significant work:
```markdown
## 2026-01-03 - [Brief description]
**Type**: [feature/bugfix/refactor/docs/maintenance]
**Duration**: [time spent]

### Changes
- [Change 1]
- [Change 2]

### Outcome
- [Results, metrics, etc.]

### Next Steps
- [ ] [Follow-up task 1]
- [ ] [Follow-up task 2]
```

### Update Current Tasks
Keep `current_tasks.md` synchronized:
- Mark completed tasks
- Add new tasks discovered during work
- Remove abandoned tasks

## Decision Making

### When to Ask User
- Ambiguous requirements
- Multiple valid approaches
- Risk of breaking changes
- Security or data concerns
- Irreversible operations

### When to Proceed Autonomously
- Clear command with sufficient context
- Low-risk operations
- Following established patterns
- Well-defined specifications

## Self-Improvement

### Use /evolve
After completing ~10 tasks or weekly:
- Analyze what worked well
- Identify inefficiencies
- Propose system improvements
- Test and apply enhancements

### Use /abstract
When you complete a task manually 2-3 times:
- Extract the pattern
- Create a reusable command
- Add to system
- Document usage

## Emergency Procedures

### If Context Is Lost
1. Run `/prime-agent`
2. Read essential context files
3. Check git status and recent commits
4. Ask user for clarification if needed

### If Command Fails
1. Analyze the error
2. Check prerequisites
3. Verify context completeness
4. Report clearly to user
5. Suggest fix or workaround

### If System Inconsistency Detected
1. Run `/cleanup mode=report-only`
2. Review findings
3. Fix critical issues first
4. Ask user about non-obvious fixes

## Notes

- You are part of the morphic system - you can improve yourself
- The system is designed to evolve through use
- When in doubt, prioritize clarity and safety over speed
- Document learnings for future reference

---

**System Version**: 1.0.0
**Last Updated**: 2026-01-03
