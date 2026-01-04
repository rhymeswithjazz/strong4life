# System Overview - Strong4Life

## Purpose
Strong4Life is a mobile-friendly workout tracking web application for the "Strong for Life" 3-day A/B workout split program. It tracks progressive overload, suggests weights, and helps users monitor strength gains over time. Designed for self-hosting on Synology NAS via Docker.

## Architecture

### High-Level Architecture
```
User Browser (Mobile-First)
    ↓
Phoenix LiveView (Real-time UI)
    ↓
Context Layer (Business Logic)
    ├── Accounts Context (Authentication)
    └── Workouts Context (Core Domain)
        ↓
PostgreSQL Database (Data Persistence)
```

### Key Components

**Frontend:**
- **Phoenix LiveView** - Server-rendered, real-time UI with WebSocket communication
- **Tailwind CSS** - Utility-first styling, mobile-first responsive design
- **No JavaScript framework** - Pure LiveView, minimal client-side JS

**Backend:**
- **Phoenix Framework** - Web framework and routing
- **Ecto** - Database wrapper and query builder
- **Contexts** - Domain-driven design with Accounts and Workouts contexts
- **phx.gen.auth** - Scope-based authentication with bcrypt

**Data Layer:**
- **PostgreSQL 16** - Primary database
- **Binary UUIDs** - For WorkoutSession and related tables
- **Integer IDs** - For User table (auto-increment)

**Infrastructure:**
- **Docker + Docker Compose** - Containerization
- **GitHub Actions** - CI/CD pipeline
- **Docker Hub** - Container registry
- **Portainer** - Deployment management on Synology NAS

### Tech Stack
- **Language**: Elixir 1.15+
- **Framework**: Phoenix 1.8.3+ with LiveView 1.1+
- **Database**: PostgreSQL 16
- **Styling**: Tailwind CSS v4
- **Authentication**: phx.gen.auth (scope-based)
- **Email**: Swoosh with SMTP adapter
- **HTTP Client**: Req (not httpoison/tesla/httpc)
- **Deployment**: Docker + Portainer on Synology NAS

## Data Model

### Core Schemas

**Accounts Context:**
- `User` - User accounts with email/password authentication

**Workouts Context:**
- `Exercise` - Exercise definitions (Squat, Bench Press, Deadlift, etc.)
- `WorkoutTemplate` - Pre-defined workout programs (Workout A, Workout B)
- `WorkoutTemplateExercise` - Join table linking exercises to templates with target sets/reps
- `WorkoutSession` - User's actual workout instances (tracks started_at, completed_at)
- `WorkoutSet` - Individual sets logged during a session (weight, reps, RPE)

### Key Relationships
```
User --< WorkoutSession >-- WorkoutTemplate
WorkoutSession --< WorkoutSet >-- Exercise
WorkoutTemplate --< WorkoutTemplateExercise >-- Exercise
```

**Progressive Overload Logic:**
- Compare `WorkoutSet` records across multiple `WorkoutSession` instances
- Suggested weights derive from the last completed set for that exercise
- RPE (Rate of Perceived Exertion) tracked per set

## Development Principles

### Functional Programming (from Global CLAUDE.md)
- **Pure functions** - No side effects where possible
- **Immutable data** - Create new data structures instead of mutating
- **Mutation exceptions** - Only when absolutely necessary for performance
- **Composition over inheritance**
- **Declarative over imperative**

### Phoenix/LiveView Patterns (from Project CLAUDE.md)
- **Scope-based authentication** - Always use `@current_scope.user`, never `@current_user`
- **Streams over assigns** - Use `stream/3` for lists to avoid memory issues
- **Mobile-first design** - Large touch targets (44px minimum)
- **No inline scripts** - Use colocated hooks or external hooks in `assets/js/`
- **Context-based architecture** - Business logic in context modules

### Code Quality
- Self-documenting code with clear, descriptive names
- Small, focused functions with single responsibility
- Explicit over implicit behavior
- Graceful, predictable error handling
- Comprehensive test coverage

### Testing
- Unit test coverage target: 80%+
- Integration tests for context functions
- LiveView tests for user interactions
- Test-driven development encouraged

### Git Workflow
- Feature branches for all work
- Descriptive commit messages following template:
  ```
  (feature|bug fix|refactor): brief description

  Detailed explanation:
  - Specific change 1
  - Specific change 2
  ```
- Atomic commits - one logical unit per commit
- Commit frequently (at least hourly during active development)

## Infrastructure

### Development
- Docker Compose for PostgreSQL
- `mix phx.server` for local development
- Asset compilation with esbuild + Tailwind
- Git hooks for auto-formatting on commit

### Production
- Docker container built via GitHub Actions
- Pushed to Docker Hub on main branch commits
- Deployed via Portainer on Synology NAS
- Health check endpoint: `/health`
- Environment variables in Portainer stack config

### CI/CD
- GitHub Actions workflows
- Build and push Docker images
- Run tests before deployment
- Automated database migrations

## Common Operations

### Development Workflow
```bash
# Setup
docker compose up -d        # Start PostgreSQL
mix setup                   # Install deps, setup DB
mix phx.server             # Start server

# Testing
mix test                   # Run all tests
mix test --failed          # Re-run failures

# Database
mix ecto.reset            # Fresh database
mix run priv/repo/seeds.exs  # Re-run seeds (idempotent)

# Code Quality
mix precommit             # Compile, format, test
```

### Production Deployment
```bash
# Automated via GitHub Actions
git push origin main      # Triggers CI/CD pipeline
# → Builds Docker image
# → Pushes to Docker Hub
# → Portainer pulls and deploys
```

## Important Constraints

1. **No external JS frameworks** - Pure LiveView, no React/Vue/etc.
2. **Use Req library** - Not httpoison/tesla/httpc for HTTP requests
3. **Scope-based auth** - Always `@current_scope.user`, never `@current_user`
4. **Binary UUIDs** - WorkoutSession and related tables
5. **Integer IDs** - User table (standard auto-increment)
6. **Mobile-first** - Design for phone screens, this is a gym app
7. **Idempotent seeds** - Safe to re-run `priv/repo/seeds.exs`

## Security Considerations

- bcrypt password hashing (from phx.gen.auth)
- Session-based authentication
- CSRF protection enabled
- User-scoped queries in context layer
- Input validation at boundaries
- Secure environment variable management

---

**Created**: 2026-01-03
**Last Updated**: 2026-01-03
