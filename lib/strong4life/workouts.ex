defmodule Strong4life.Workouts do
  @moduledoc """
  The Workouts context - handles all workout-related business logic.
  """

  import Ecto.Query, warn: false
  alias Strong4life.Repo

  alias Strong4life.Workouts.{
    Exercise,
    WorkoutTemplate,
    WorkoutTemplateExercise,
    WorkoutSession,
    WorkoutSet
  }

  # ============================================
  # Exercises
  # ============================================

  @doc """
  Returns the list of exercises.
  """
  def list_exercises do
    Repo.all(from e in Exercise, order_by: [asc: e.name])
  end

  @doc """
  Gets a single exercise by ID.
  """
  def get_exercise!(id), do: Repo.get!(Exercise, id)

  @doc """
  Gets an exercise by name.
  """
  def get_exercise_by_name(name), do: Repo.get_by(Exercise, name: name)

  @doc """
  Creates an exercise.
  """
  def create_exercise(attrs \\ %{}) do
    %Exercise{}
    |> Exercise.changeset(attrs)
    |> Repo.insert()
  end

  # ============================================
  # Workout Templates
  # ============================================

  @doc """
  Returns the list of workout templates with their exercises.
  """
  def list_workout_templates do
    WorkoutTemplate
    |> preload(workout_template_exercises: :exercise)
    |> Repo.all()
  end

  @doc """
  Gets a single workout template with exercises.
  """
  def get_workout_template!(id) do
    WorkoutTemplate
    |> preload(workout_template_exercises: :exercise)
    |> Repo.get!(id)
  end

  @doc """
  Gets a workout template by name.
  """
  def get_workout_template_by_name(name) do
    WorkoutTemplate
    |> preload(workout_template_exercises: :exercise)
    |> Repo.get_by(name: name)
  end

  @doc """
  Creates a workout template.
  """
  def create_workout_template(attrs \\ %{}) do
    %WorkoutTemplate{}
    |> WorkoutTemplate.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Adds an exercise to a workout template.
  """
  def add_exercise_to_template(template_id, exercise_id, attrs) do
    %WorkoutTemplateExercise{}
    |> WorkoutTemplateExercise.changeset(
      Map.merge(attrs, %{workout_template_id: template_id, exercise_id: exercise_id})
    )
    |> Repo.insert()
  end

  # ============================================
  # Workout Sessions
  # ============================================

  @doc """
  Returns all workout sessions for a user.
  """
  def list_user_sessions(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    WorkoutSession
    |> where([s], s.user_id == ^user_id)
    |> order_by([s], desc: s.started_at)
    |> limit(^limit)
    |> offset(^offset)
    |> preload([:workout_template, workout_sets: :exercise])
    |> Repo.all()
  end

  @doc """
  Gets a single workout session.
  """
  def get_session!(id) do
    WorkoutSession
    |> preload([:workout_template, workout_sets: :exercise])
    |> Repo.get!(id)
  end

  @doc """
  Gets the user's last completed workout of a specific template type.
  """
  def get_last_session_for_template(user_id, template_id) do
    WorkoutSession
    |> where([s], s.user_id == ^user_id and s.workout_template_id == ^template_id)
    |> where([s], not is_nil(s.completed_at))
    |> order_by([s], desc: s.completed_at)
    |> limit(1)
    |> preload(workout_sets: :exercise)
    |> Repo.one()
  end

  @doc """
  Gets the total count of completed workouts for a user.
  """
  def count_completed_sessions(user_id) do
    WorkoutSession
    |> where([s], s.user_id == ^user_id and not is_nil(s.completed_at))
    |> Repo.aggregate(:count)
  end

  @doc """
  Calculates the current workout streak for a user.
  Returns the number of consecutive weeks with at least one workout.
  """
  def calculate_streak(user_id) do
    # Get all completed sessions ordered by date
    sessions =
      WorkoutSession
      |> where([s], s.user_id == ^user_id and not is_nil(s.completed_at))
      |> order_by([s], desc: s.completed_at)
      |> select([s], s.completed_at)
      |> Repo.all()

    calculate_weekly_streak(sessions)
  end

  defp calculate_weekly_streak([]), do: 0

  defp calculate_weekly_streak(sessions) do
    today = Date.utc_today()
    current_week = Date.beginning_of_week(today)

    sessions
    |> Enum.map(&Date.beginning_of_week(DateTime.to_date(&1)))
    |> Enum.uniq()
    |> Enum.sort(:desc)
    |> count_consecutive_weeks(current_week, 0)
  end

  defp count_consecutive_weeks([], _expected_week, count), do: count

  defp count_consecutive_weeks([week | rest], expected_week, count) do
    # Allow for current week or previous week to count
    diff = Date.diff(expected_week, week)

    cond do
      diff == 0 ->
        # This week matches
        count_consecutive_weeks(rest, Date.add(expected_week, -7), count + 1)

      diff == 7 and count == 0 ->
        # First week is last week (still in streak)
        count_consecutive_weeks([week | rest], Date.add(expected_week, -7), count)

      true ->
        # Streak broken
        count
    end
  end

  @doc """
  Determines which workout (A or B) should be done next based on workout history.
  """
  def get_next_workout_type(user_id) do
    last_session =
      WorkoutSession
      |> where([s], s.user_id == ^user_id and not is_nil(s.completed_at))
      |> order_by([s], desc: s.completed_at)
      |> limit(1)
      |> preload(:workout_template)
      |> Repo.one()

    case last_session do
      nil -> "Workout A"
      %{workout_template: %{name: "Workout A"}} -> "Workout B"
      %{workout_template: %{name: "Workout B"}} -> "Workout A"
      _ -> "Workout A"
    end
  end

  @doc """
  Starts a new workout session.
  """
  def start_session(user_id, template_id) do
    %WorkoutSession{}
    |> WorkoutSession.changeset(%{
      user_id: user_id,
      workout_template_id: template_id,
      started_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.insert()
  end

  @doc """
  Completes a workout session.
  """
  def complete_session(session, attrs \\ %{}) do
    session
    |> WorkoutSession.complete_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets the current in-progress session for a user, if any.
  """
  def get_in_progress_session(user_id) do
    WorkoutSession
    |> where([s], s.user_id == ^user_id and is_nil(s.completed_at))
    |> order_by([s], desc: s.started_at)
    |> limit(1)
    |> preload([:workout_template, workout_sets: :exercise])
    |> Repo.one()
  end

  # ============================================
  # Workout Sets
  # ============================================

  @doc """
  Logs a set for a workout session.
  """
  def log_set(attrs) do
    %WorkoutSet{}
    |> WorkoutSet.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a logged set.
  """
  def update_set(%WorkoutSet{} = set, attrs) do
    set
    |> WorkoutSet.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets or creates a set for a session/exercise/set_number combination.
  This allows for updating sets as the user progresses through the workout.
  """
  def upsert_set(attrs) do
    case Repo.get_by(WorkoutSet,
           workout_session_id: attrs.workout_session_id,
           exercise_id: attrs.exercise_id,
           set_number: attrs.set_number
         ) do
      nil -> log_set(attrs)
      existing -> update_set(existing, attrs)
    end
  end

  @doc """
  Gets the suggested weight for an exercise based on last session's performance.
  Returns the weight used in the last session, or nil if no history.
  """
  def get_suggested_weight(user_id, exercise_id) do
    WorkoutSet
    |> join(:inner, [ws], s in WorkoutSession, on: ws.workout_session_id == s.id)
    |> where([ws, s], s.user_id == ^user_id and ws.exercise_id == ^exercise_id)
    |> where([ws, s], not is_nil(s.completed_at))
    |> order_by([ws, s], desc: s.completed_at)
    |> limit(1)
    |> select([ws], ws.weight)
    |> Repo.one()
  end

  @doc """
  Gets the weight history for an exercise for progress charts.
  Returns a list of {date, max_weight} tuples.
  """
  def get_exercise_weight_history(user_id, exercise_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 30)

    WorkoutSet
    |> join(:inner, [ws], s in WorkoutSession, on: ws.workout_session_id == s.id)
    |> where([ws, s], s.user_id == ^user_id and ws.exercise_id == ^exercise_id)
    |> where([ws, s], not is_nil(s.completed_at) and not is_nil(ws.weight))
    |> group_by([ws, s], fragment("DATE(?)", s.completed_at))
    |> order_by([ws, s], desc: fragment("DATE(?)", s.completed_at))
    |> limit(^limit)
    |> select([ws, s], %{
      date: fragment("DATE(?)", s.completed_at),
      max_weight: max(ws.weight)
    })
    |> Repo.all()
    |> Enum.reverse()
  end

  @doc """
  Gets volume history (sets x reps x weight) for an exercise.
  """
  def get_exercise_volume_history(user_id, exercise_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 30)

    WorkoutSet
    |> join(:inner, [ws], s in WorkoutSession, on: ws.workout_session_id == s.id)
    |> where([ws, s], s.user_id == ^user_id and ws.exercise_id == ^exercise_id)
    |> where(
      [ws, s],
      not is_nil(s.completed_at) and not is_nil(ws.weight) and not is_nil(ws.reps)
    )
    |> group_by([ws, s], fragment("DATE(?)", s.completed_at))
    |> order_by([ws, s], desc: fragment("DATE(?)", s.completed_at))
    |> limit(^limit)
    |> select([ws, s], %{
      date: fragment("DATE(?)", s.completed_at),
      volume: sum(ws.weight * ws.reps)
    })
    |> Repo.all()
    |> Enum.reverse()
  end
end
