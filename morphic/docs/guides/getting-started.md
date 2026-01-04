# Getting Started - Strong4Life Morphic System

## Step 1: Initialize Your Session

```bash
/prime-agent
```

This loads all necessary context and prepares the agent to work on Strong4Life. It reads:
- Project overview and architecture
- Coding conventions and patterns
- Recent progress and active tasks
- Git status and recent commits
- CLAUDE.md files (global and project-specific)

## Step 2: Understand the System

Review these files to understand the morphic system:
- `morphic/README.md` - Morphic system overview
- `morphic/AGENT.md` - Agent instructions and behavior
- `morphic/docs/references/command-reference.md` - Available commands
- `morphic/context/system/overview.md` - Strong4Life architecture
- `morphic/context/system/conventions.md` - Coding standards

## Step 3: Try a Simple Command

```bash
# Check system health
/cleanup mode=report-only

# Or run tests
/run-tests
```

## Step 4: Build Your First Feature

```bash
/build-feature story="Add workout notes field to WorkoutSession"
```

The agent will:
1. Create a plan based on the user story
2. Implement the feature following Strong4Life patterns
3. Run tests to verify the implementation
4. Ask for your review

## Step 5: Ship It

```bash
/code-review                # Quality check
/run-tests                  # Verify all tests pass
/ship-feature              # Commit and push
```

## Daily Workflow

### Morning
```bash
/prime-agent              # Restore context
# Review morphic/progress/current_tasks.md
```

### During Development

**For new features:**
```bash
/build-feature story="User story here"
/run-tests
/code-review
/ship-feature
```

**For bug fixes:**
```bash
/debug issue="Description of the bug"
/run-tests
/ship-feature
```

**For refactoring:**
```bash
/refactor target=WorkoutsContext goal="Extract query logic"
/run-tests
/code-review
/ship-feature
```

### End of Day
```bash
/cleanup                  # Maintain system health

# Manually update:
# - morphic/progress/progress_log.md (add entry for significant work)
# - morphic/progress/current_tasks.md (mark completed, add new tasks)

# Optional: commit progress
git add morphic/
git commit -m "docs: update morphic progress tracking"
```

## Weekly Maintenance

```bash
/update-deps type=minor   # Update dependencies
/cleanup                  # System health check

# Review progress
cat morphic/progress/progress_log.md
```

## Monthly Evolution

```bash
/evolve                   # Improve the morphic system
/cleanup                  # Verify consistency
```

## Strong4Life-Specific Tips

### Authentication Patterns
Always remember:
```elixir
# ✅ GOOD
def mount(_params, _session, socket) do
  current_scope = socket.assigns.current_scope
  user = current_scope.user
  # ...
end

# ❌ BAD
def mount(_params, _session, socket) do
  user = socket.assigns.current_user  # WRONG!
  # ...
end
```

### LiveView Development
- Use `stream/3` for lists of workout sets, history entries, etc.
- Minimum 44px touch targets for mobile
- Test on mobile viewport sizes
- No inline `<script>` tags

### Database Work
- WorkoutSession and related tables: `:binary_id` (UUIDs)
- User table: integer IDs
- Seeds are idempotent: `mix run priv/repo/seeds.exs`

### Common Commands
```bash
# Development
mix phx.server                    # Start server
mix test                          # Run tests
mix format                        # Format code

# Database
mix ecto.reset                    # Fresh database
mix ecto.gen.migration name       # New migration

# Pre-commit
mix precommit                     # Compile, format, test
```

## Troubleshooting

### Context Lost
```bash
/prime-agent
```

### System Feels Inconsistent
```bash
/cleanup
```

### Command Failing
1. Read the command file in `morphic/commands/`
2. Check prerequisites (e.g., is database running?)
3. Verify context is loaded with `/prime-agent`
4. Ask agent for clarification

### Tests Failing
```bash
# Run specific test
mix test test/path/to/test_file.exs

# Re-run just failed tests
mix test --failed

# Check test output for details
```

### Need Help
- Check `morphic/docs/references/command-reference.md` for command usage
- Read command documentation in `morphic/commands/` directory
- Review `morphic/AGENT.md` for agent behavior
- Check `CLAUDE.md` for project-specific patterns

## Advanced Usage

### Morphing Commands
Customize commands inline with natural language:
```bash
/run-tests but skip integration tests and focus on context tests
/code-review focus=security thoroughness=10
/build-feature story="..." but use TDD approach
```

### Creating Custom Commands
After doing a task 2-3 times manually:
```bash
/abstract task="The manual task you completed"
# Agent will create a reusable command in morphic/commands/
```

### System Evolution
Periodically improve the morphic system:
```bash
/evolve aggressiveness=balanced
# Agent analyzes recent work and proposes improvements
# Can create new commands, improve existing ones, update documentation
```

---

**Created**: 2026-01-03
**Last Updated**: 2026-01-03
