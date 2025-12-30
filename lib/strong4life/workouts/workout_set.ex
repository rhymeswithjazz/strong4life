defmodule Strong4life.Workouts.WorkoutSet do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "workout_sets" do
    field :set_number, :integer
    field :weight, :decimal
    field :reps, :integer
    field :rpe, :integer
    field :notes, :string

    belongs_to :workout_session, Strong4life.Workouts.WorkoutSession
    belongs_to :exercise, Strong4life.Workouts.Exercise

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout_set, attrs) do
    workout_set
    |> cast(attrs, [:workout_session_id, :exercise_id, :set_number, :weight, :reps, :rpe, :notes])
    |> validate_required([:workout_session_id, :exercise_id, :set_number])
    |> validate_number(:set_number, greater_than: 0, less_than_or_equal_to: 10)
    |> validate_number(:weight, greater_than_or_equal_to: 0)
    |> validate_number(:reps, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_number(:rpe, greater_than_or_equal_to: 1, less_than_or_equal_to: 10)
    |> foreign_key_constraint(:workout_session_id)
    |> foreign_key_constraint(:exercise_id)
    |> unique_constraint([:workout_session_id, :exercise_id, :set_number])
  end
end

