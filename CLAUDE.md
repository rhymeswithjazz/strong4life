# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Strong4Life is a mobile-friendly workout tracking web application built with Elixir/Phoenix and LiveView. It implements the "Strong for Life" 3-day A/B workout split program with progressive overload tracking, designed for self-hosting on Synology NAS via Docker.

## Tech Stack

- **Language**: Elixir 1.15+
- **Framework**: Phoenix 1.8.3+
- **Frontend**: Phoenix LiveView 1.1+ (no separate JavaScript framework)
- **Database**: PostgreSQL 16
- **Styling**: Tailwind CSS
- **Email**: Swoosh with SMTP adapter
- **Authentication**: phx.gen.auth (bcrypt_elixir)
- **HTTP Client**: Req (not httpoison, tesla, or httpc)
- **Containerization**: Docker + Docker Compose

## Common Commands

### Development Setup
```bash
# Start PostgreSQL (Docker)
docker compose up -d

# Install dependencies and setup database (runs migrations + seeds)
mix setup

# Start Phoenix server
mix phx.server

# Visit http://localhost:4000
```

### Development Workflow
```bash
# Setup git hooks (auto-format on commit)
./scripts/setup-git-hooks.sh

# Run tests
mix test

# Run specific test file
mix test test/path/to/test_file.exs

# Run previously failed tests
mix test --failed

# Run pre-commit checks (compile with warnings as errors, unlock unused deps, format, test)
mix precommit

# Database operations
mix ecto.reset        # Drop, create, migrate, and seed
mix ecto.migrate      # Run pending migrations
mix run priv/repo/seeds.exs  # Re-run seeds (idempotent)

# Generate migration
mix ecto.gen.migration migration_name_using_underscores

# Asset compilation
mix assets.build      # Compile Tailwind + esbuild
mix assets.deploy     # Minify and digest for production
```

### Production
```bash
# Generate secret for production
mix phx.gen.secret
```

## Architecture Overview

### Data Model & Domain Structure

The application uses a **context-based architecture** with two primary contexts:

1. **Accounts Context** (`lib/strong4life/accounts.ex`)
   - User authentication and session management
   - Uses Phoenix's phx.gen.auth with scope-based authentication
   - Key schema: `User`

2. **Workouts Context** (`lib/strong4life/workouts.ex`)
   - Core domain logic for workout tracking
   - Key schemas:
     - `Exercise` - Exercise definitions (Barbell Squat, Bench Press, etc.)
     - `WorkoutTemplate` - Pre-defined workout programs (Workout A, Workout B)
     - `WorkoutTemplateExercise` - Join table linking exercises to templates with target sets/reps
     - `WorkoutSession` - User's actual workout instances (tracks started_at, completed_at)
     - `WorkoutSet` - Individual sets logged during a session (weight, reps, RPE)

**Key Relationships:**
- `WorkoutSession` belongs to both `User` and `WorkoutTemplate`
- `WorkoutSession` has many `WorkoutSet` records
- `WorkoutSet` belongs to `WorkoutSession` and references `Exercise`
- Users track progress by comparing `WorkoutSet` records across multiple `WorkoutSession` instances

### LiveView Routes & Authentication

The router defines three authentication levels:

1. **Public Routes** (`:browser` pipeline only)
   - Home page, login page
   - `@current_scope` available but may be nil

2. **Redirect-if-Authenticated Routes** (`:redirect_if_user_is_authenticated` plug)
   - Registration page
   - Redirects logged-in users away

3. **Authenticated Routes** (`live_session :require_authenticated_user`)
   - All workout tracking LiveViews (Dashboard, Workout, History, Progress)
   - Uses `on_mount: [{Strong4lifeWeb.UserAuth, :ensure_authenticated}]`
   - `@current_scope` guaranteed to exist

**Authentication Pattern:**
- Access user via `@current_scope.user` in templates (NOT `@current_user`)
- Always pass `current_scope` as first argument to context functions
- User ID filtering happens in context layer via `current_scope.user.id`

### LiveView Pages

- **DashboardLive** - Select which workout to start (A or B)
- **WorkoutLive** - Active workout session with set logging
- **HistoryLive** - Past workout sessions list and detail view
- **ProgressLive** - Progress charts and strength gains visualization

### Seeds & Data Initialization

`priv/repo/seeds.exs` is **idempotent** and creates:
- Core exercises (Squat, Bench, Deadlift, OHP, Row, CGBP, Face Pulls, Lunges)
- Two workout templates (Workout A, Workout B)
- Links exercises to templates with target sets/reps

Run `mix run priv/repo/seeds.exs` safely multiple times.

## Project-Specific Guidelines

### Authentication & Scopes

This project uses **scope-based authentication** from phx.gen.auth:
- The plug `:fetch_current_scope_for_user` is in the default `:browser` pipeline
- Authenticated routes require `:require_authenticated_user` plug
- LiveView sessions use `on_mount: [{Strong4lifeWeb.UserAuth, :ensure_authenticated}]`
- **ALWAYS** pass `current_scope={@current_scope}` when using `<Layouts.app>` in LiveViews
- **NEVER** use `@current_user` - use `@current_scope.user` instead

### Workout Context Patterns

When adding workout-related features:
- User-scoped queries must filter by `user_id` from `current_scope.user`
- Progressive overload logic compares `WorkoutSet` records from previous sessions
- Suggested weights derive from the last completed set for that exercise
- RPE (Rate of Perceived Exertion) is tracked per set

### LiveView Patterns

- **Streams over assigns**: Use `stream/3` for workout sets and history lists to avoid memory issues
- Always provide `phx-update="stream"` with unique DOM IDs
- Re-stream items with `stream_insert/3` when updating individual items
- For empty states with streams, use Tailwind's `hidden only:block` pattern

### UI/UX Standards

- **Mobile-first**: Design for phone screens, this is a gym app
- **PWA-ready**: Ensure touch targets are large enough (minimum 44px)
- Use Heroicons via `<.icon name="hero-x-mark" />` component (imported from core_components.ex)
- Tailwind v4 syntax: CSS imports in `app.css` with `@import "tailwindcss"`
- No inline `<script>` tags - use colocated hooks or external hooks in `assets/js/`

### Docker & Production

- GitHub Actions builds and pushes to Docker Hub on main branch commits
- Portainer stack deployment pulls from Docker Hub
- Environment variables are set in Portainer stack configuration
- Health check endpoint: `/health` (returns JSON status)

## Important Constraints

- **No external JS frameworks** - Pure LiveView, no React/Vue/etc.
- **Use Req library** for HTTP requests, not httpoison/tesla/httpc
- **Scope-based auth** - Always use `@current_scope.user`, never `@current_user`
- **Binary UUIDs** - WorkoutSession and related tables use `:binary_id` primary keys
- **Integer IDs** - User table uses standard integer IDs (auto-increment)
