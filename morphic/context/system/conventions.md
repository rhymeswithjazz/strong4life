# Coding Conventions - Strong4Life

## Elixir Naming Conventions

### Modules
```elixir
# Good: PascalCase
defmodule Strong4lifeWeb.WorkoutLive do
  # ...
end

# Bad: snake_case or camelCase
defmodule strong4life_web.workout_live do
  # ...
end
```

### Functions
```elixir
# Good: snake_case, descriptive
def get_previous_workout_sets(current_scope, exercise_id) do
  # ...
end

# Bad: camelCase or abbreviations
def getPrevSets(scope, ex_id) do
  # ...
end
```

### Variables
```elixir
# Good: snake_case, descriptive
active_workout_session = Workouts.get_active_session(current_scope)

# Bad: camelCase or single letters
activeSession = Workouts.get_active_session(s)
```

### Atoms
```elixir
# Good: lowercase snake_case
:workout_session
:in_progress
:completed

# Bad: camelCase or mixed
:workoutSession
:InProgress
```

## File Organization

### Directory Structure
```
lib/
├── strong4life/              # Business logic (contexts)
│   ├── accounts.ex          # Accounts context
│   ├── accounts/            # Accounts schemas
│   │   └── user.ex
│   ├── workouts.ex          # Workouts context
│   └── workouts/            # Workouts schemas
│       ├── exercise.ex
│       ├── workout_template.ex
│       ├── workout_session.ex
│       └── workout_set.ex
├── strong4life_web/          # Web interface (LiveViews)
│   ├── components/          # Reusable components
│   ├── controllers/         # Traditional controllers
│   └── live/                # LiveView modules
│       ├── dashboard_live.ex
│       ├── workout_live.ex
│       └── history_live.ex
└── strong4life_web.ex        # Web module definitions

test/
├── strong4life/              # Context tests
│   ├── accounts_test.exs
│   └── workouts_test.exs
├── strong4life_web/          # Web tests
│   └── live/
│       ├── dashboard_live_test.exs
│       └── workout_live_test.exs
└── support/                  # Test helpers
```

### File Naming
- **Schemas**: `singular_noun.ex` (e.g., `workout_session.ex`)
- **Contexts**: `plural_noun.ex` (e.g., `workouts.ex`)
- **LiveViews**: `name_live.ex` (e.g., `workout_live.ex`)
- **Tests**: `name_test.exs` (e.g., `workouts_test.exs`)

## Code Organization Patterns

### Context Functions (Public API)
```elixir
defmodule Strong4life.Workouts do
  # Always pass current_scope as first argument
  def list_workout_sessions(current_scope) do
    # Filter by user_id from current_scope
    WorkoutSession
    |> where([ws], ws.user_id == ^current_scope.user.id)
    |> Repo.all()
  end

  # Good: Descriptive function names
  def get_active_workout_session(current_scope) do
    # ...
  end

  # Good: Functions return tagged tuples or structs
  def create_workout_session(current_scope, attrs) do
    %WorkoutSession{}
    |> WorkoutSession.changeset(attrs)
    |> Repo.insert()
  end
end
```

### Schema Modules (Data Layer)
```elixir
defmodule Strong4life.Workouts.WorkoutSession do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "workout_sessions" do
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime

    belongs_to :user, Strong4life.Accounts.User, type: :id
    belongs_to :workout_template, Strong4life.Workouts.WorkoutTemplate
    has_many :workout_sets, Strong4life.Workouts.WorkoutSet

    timestamps()
  end

  # Changesets for validation
  def changeset(workout_session, attrs) do
    workout_session
    |> cast(attrs, [:started_at, :completed_at, :user_id, :workout_template_id])
    |> validate_required([:started_at, :user_id, :workout_template_id])
  end
end
```

### LiveView Modules (UI Layer)
```elixir
defmodule Strong4lifeWeb.WorkoutLive do
  use Strong4lifeWeb, :live_view
  alias Strong4life.Workouts

  # Mount: Initialize LiveView
  def mount(_params, _session, socket) do
    # IMPORTANT: current_scope available from on_mount hook
    current_scope = socket.assigns.current_scope

    # Load initial data
    {:ok,
     socket
     |> assign(:page_title, "Workout")
     |> load_workout_data()}
  end

  # Handle events
  def handle_event("log_set", %{"weight" => weight, "reps" => reps}, socket) do
    # Always pass current_scope to context functions
    case Workouts.log_set(socket.assigns.current_scope, %{weight: weight, reps: reps}) do
      {:ok, workout_set} ->
        # Use stream_insert for lists
        {:noreply, stream_insert(socket, :workout_sets, workout_set)}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  # Prefer private helper functions
  defp load_workout_data(socket) do
    current_scope = socket.assigns.current_scope

    socket
    |> assign(:active_session, Workouts.get_active_session(current_scope))
    |> stream(:workout_sets, Workouts.list_sets_for_session(current_scope))
  end
end
```

## Authentication Patterns

### CRITICAL: Scope-Based Authentication
```elixir
# ✅ GOOD: Always use current_scope
def mount(_params, _session, socket) do
  current_scope = socket.assigns.current_scope
  user = current_scope.user

  {:ok, assign(socket, :user, user)}
end

# ✅ GOOD: Pass current_scope to context functions
Workouts.list_workout_sessions(current_scope)

# ❌ BAD: Never use @current_user
def mount(_params, _session, socket) do
  user = socket.assigns.current_user  # WRONG!
  # ...
end

# ❌ BAD: Never access user directly without current_scope
Workouts.list_workout_sessions(user_id)  # WRONG!
```

### Template Authentication
```heex
<!-- ✅ GOOD: Use @current_scope.user -->
<p>Welcome, <%= @current_scope.user.email %>!</p>

<!-- ✅ GOOD: Pass current_scope to layout -->
<Layouts.app current_scope={@current_scope}>
  <!-- content -->
</Layouts.app>

<!-- ❌ BAD: Never use @current_user -->
<p>Welcome, <%= @current_user.email %>!</p>
```

## LiveView Best Practices

### Use Streams for Lists
```elixir
# ✅ GOOD: Use streams for efficient list updates
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> stream(:workout_sets, list_workout_sets())
   |> assign(:page_title, "Workout")}
end

def handle_event("add_set", params, socket) do
  {:ok, workout_set} = create_workout_set(params)
  {:noreply, stream_insert(socket, :workout_sets, workout_set)}
end

# Template with stream
<div id="workout-sets" phx-update="stream">
  <div :for={{dom_id, set} <- @streams.workout_sets} id={dom_id}>
    <%= set.weight %> lbs × <%= set.reps %> reps
  </div>
</div>

# ❌ BAD: Assigning entire list and re-rendering
def mount(_params, _session, socket) do
  {:ok, assign(socket, :workout_sets, list_workout_sets())}
end

def handle_event("add_set", params, socket) do
  {:ok, workout_set} = create_workout_set(params)
  all_sets = socket.assigns.workout_sets ++ [workout_set]
  {:noreply, assign(socket, :workout_sets, all_sets)}
end
```

### Mobile-First Design
```elixir
# Component with mobile-first touch targets
def button(assigns) do
  ~H"""
  <button class="
    min-h-[44px] min-w-[44px]  <!-- Minimum touch target -->
    px-4 py-2
    text-lg                     <!-- Readable text size -->
    rounded-lg
    bg-blue-600 text-white
    active:bg-blue-700          <!-- Clear touch feedback -->
  ">
    <%= render_slot(@inner_block) %>
  </button>
  """
end
```

## Error Handling

### Context Functions
```elixir
# ✅ GOOD: Return tagged tuples
def create_workout_session(current_scope, attrs) do
  %WorkoutSession{}
  |> WorkoutSession.changeset(attrs)
  |> Repo.insert()
  # Returns {:ok, session} or {:error, changeset}
end

# ✅ GOOD: Handle both cases in LiveView
def handle_event("start_workout", params, socket) do
  case Workouts.create_workout_session(socket.assigns.current_scope, params) do
    {:ok, session} ->
      {:noreply,
       socket
       |> put_flash(:info, "Workout started!")
       |> assign(:active_session, session)}

    {:error, changeset} ->
      {:noreply,
       socket
       |> put_flash(:error, "Failed to start workout")
       |> assign(:changeset, changeset)}
  end
end

# ❌ BAD: Silent failures
def create_workout_session(current_scope, attrs) do
  try do
    # ...
  rescue
    _ -> nil  # Silent failure - don't do this!
  end
end
```

### Database Queries
```elixir
# ✅ GOOD: Explicit error handling with pattern matching
def get_workout_session(current_scope, id) do
  case Repo.get_by(WorkoutSession, id: id, user_id: current_scope.user.id) do
    nil -> {:error, :not_found}
    session -> {:ok, session}
  end
end

# ✅ GOOD: Use Repo.get! when you expect it to exist (let it raise)
def get_workout_session!(current_scope, id) do
  Repo.get_by!(WorkoutSession, id: id, user_id: current_scope.user.id)
end
```

## Import Order
```elixir
defmodule Strong4life.Workouts do
  # 1. Core library imports
  import Ecto.Query, warn: false

  # 2. Application aliases
  alias Strong4life.Repo
  alias Strong4life.Workouts.{Exercise, WorkoutSession, WorkoutSet}

  # 3. External dependencies (if needed)
  # alias SomeExternalLib

  # Function definitions follow
end
```

## Testing Patterns

### Context Tests
```elixir
defmodule Strong4life.WorkoutsTest do
  use Strong4life.DataCase

  alias Strong4life.Workouts

  describe "workout_sessions" do
    setup do
      # Create test user and scope
      user = user_fixture()
      current_scope = %{user: user}

      {:ok, current_scope: current_scope}
    end

    test "list_workout_sessions/1 returns user's sessions", %{current_scope: current_scope} do
      session = workout_session_fixture(user_id: current_scope.user.id)

      assert Workouts.list_workout_sessions(current_scope) == [session]
    end
  end
end
```

### LiveView Tests
```elixir
defmodule Strong4lifeWeb.WorkoutLiveTest do
  use Strong4lifeWeb.ConnCase

  import Phoenix.LiveViewTest

  test "displays active workout", %{conn: conn} do
    user = user_fixture()
    session = workout_session_fixture(user_id: user.id)

    {:ok, view, html} =
      conn
      |> log_in_user(user)
      |> live(~p"/workout")

    assert html =~ "Active Workout"
  end
end
```

## Functional Programming Patterns

### Prefer Immutable Data
```elixir
# ✅ GOOD: Create new data structures
def add_workout_set(workout_session, set_attrs) do
  %{workout_session | workout_sets: [set_attrs | workout_session.workout_sets]}
end

# ❌ BAD: Don't mutate (Elixir prevents this anyway, but the pattern applies)
# workout_session.workout_sets << set_attrs
```

### Use Pipe Operator
```elixir
# ✅ GOOD: Clear data transformation pipeline
def create_workout_session(current_scope, attrs) do
  %WorkoutSession{}
  |> WorkoutSession.changeset(attrs)
  |> put_change(:user_id, current_scope.user.id)
  |> Repo.insert()
end

# ❌ BAD: Nested function calls
def create_workout_session(current_scope, attrs) do
  Repo.insert(
    put_change(
      WorkoutSession.changeset(%WorkoutSession{}, attrs),
      :user_id,
      current_scope.user.id
    )
  )
end
```

### Pattern Matching
```elixir
# ✅ GOOD: Explicit pattern matching
def handle_event("complete_workout", _params, socket) do
  case Workouts.complete_session(socket.assigns.current_scope) do
    {:ok, session} ->
      {:noreply, redirect(socket, to: ~p"/history/#{session.id}")}
    {:error, :no_active_session} ->
      {:noreply, put_flash(socket, :error, "No active workout")}
  end
end

# ❌ BAD: Checking values with if/else
def handle_event("complete_workout", _params, socket) do
  result = Workouts.complete_session(socket.assigns.current_scope)

  if elem(result, 0) == :ok do
    session = elem(result, 1)
    {:noreply, redirect(socket, to: ~p"/history/#{session.id}")}
  else
    {:noreply, put_flash(socket, :error, "No active workout")}
  end
end
```

---

**Created**: 2026-01-03
**Last Updated**: 2026-01-03
