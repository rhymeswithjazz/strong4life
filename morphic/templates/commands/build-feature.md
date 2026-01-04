# /build-feature command

## Description
Implements a user story from planning through to completion, including code, tests, documentation, and git commits.

## Inputs
- User story ID (required): The user story identifier (e.g., "us-006", "US-007")
- Priority level (optional, default: medium): Priority for the feature
- Test coverage target (optional, default: 80%): Minimum test coverage percentage

## Workflow Steps

### Step 1: Planning & Analysis
Read the user story from `morphic/progress/plans/user_stories.md` and understand:
- User need and acceptance criteria
- Current implementation status
- Affected files and components

**Create implementation plan:**
- Identify all files that need changes
- Outline the changes needed for each file
- Estimate complexity and potential risks
- Present plan to user for approval before proceeding

**Success criteria:**
- User approves the implementation plan
- All acceptance criteria are understood

### Step 2: Implementation
Once plan is approved:
- Implement changes following existing code patterns
- Follow project conventions from CLAUDE.md
- Add inline comments only for complex logic
- Ensure code is functional-first (immutable, pure functions)

**Error handling:**
- If implementation blocks emerge → Document and consult user
- If patterns are unclear → Review similar existing code first

**Success criteria:**
- All acceptance criteria met
- Code follows project conventions
- No compilation errors

### Step 3: Testing
Write comprehensive tests for new functionality:
- Unit tests for business logic functions
- Integration tests for user flows
- Edge case coverage
- Ensure test coverage meets target (default 80%)

Run full test suite:
```bash
mix test
```

**Error handling:**
- If tests fail → Fix issues before proceeding
- If coverage is below target → Add more tests

**Success criteria:**
- All tests pass (including existing tests)
- Coverage target met
- No test regressions

### Step 4: Documentation
Update relevant documentation:
- Add/update function documentation if public API changed
- Update CONTEXT.md if architecture changed
- **Mark user story as complete in user_stories.md**:
  1. Update status to `✅ Implemented`
  2. Mark as complete in Priority Matrix with `[x]`

**Success criteria:**
- All documentation is current
- User story properly marked as complete

### Step 5: Commit
Create atomic commits with clear messages:

```bash
# Stage files
git add [relevant files]

# Create commit with descriptive message
git commit -m "$(cat <<'EOF'
[type]: [brief description]

- [Specific change 1]
- [Specific change 2]
- [Any breaking changes]

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

**Commit types:**
- `feature:` - New functionality
- `bug fix:` - Bug fixes
- `refactor:` - Code restructuring
- `test:` - Adding/updating tests
- `documentation:` - Documentation only

**Success criteria:**
- Commits are atomic (one logical change per commit)
- Commit messages are clear and descriptive
- All changes are committed

## Configuration (morphable)

Can be invoked with modifiers:
```
/build-feature us-006                           # Standard usage
/build-feature us-006 priority=high             # With priority
/build-feature us-006 coverage=90               # With coverage target
/build-feature us-006 but skip tests            # Natural language morphing
```

## Output
- Implementation plan (for approval)
- Completed feature code
- Test suite with passing tests
- Updated documentation
- Git commit(s)
- Summary of changes

## Notes
- Always get user approval on the plan before implementing
- Follow existing patterns in the codebase
- Prefer pure functions and immutability
- Write self-documenting code
- **Always update user_stories.md** when completing a user story
- Run tests before committing
- Create separate commits for distinct changes (e.g., one for implementation, one for tests)

## Relation to Morphic Principles
- **Goal-Oriented (P1)** - Focused on delivering user value through user stories
- **Self-Improvement (P3)** - Each feature implementation improves the system
- **Reproducibility (P5)** - Consistent workflow for all feature development
- **Adaptability (P4)** - Can morph based on context and requirements

---

**Created**: 2026-01-03
**Last Updated**: 2026-01-03
