defmodule Strong4life.Workouts.WorkoutSession do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "workout_sessions" do
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :notes, :string

    belongs_to :user, Strong4life.Accounts.User, type: :id
    belongs_to :workout_template, Strong4life.Workouts.WorkoutTemplate

    has_many :workout_sets, Strong4life.Workouts.WorkoutSet

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout_session, attrs) do
    workout_session
    |> cast(attrs, [:user_id, :workout_template_id, :started_at, :completed_at, :notes])
    |> validate_required([:user_id, :started_at])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:workout_template_id)
  end

  @doc """
  Changeset for completing a workout session.
  """
  def complete_changeset(workout_session, attrs \\ %{}) do
    workout_session
    |> cast(attrs, [:completed_at, :notes])
    |> put_change(:completed_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end
end

