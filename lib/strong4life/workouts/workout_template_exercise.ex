defmodule Strong4life.Workouts.WorkoutTemplateExercise do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "workout_template_exercises" do
    field :order, :integer
    field :target_sets, :integer
    field :target_reps, :integer

    belongs_to :workout_template, Strong4life.Workouts.WorkoutTemplate
    belongs_to :exercise, Strong4life.Workouts.Exercise

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout_template_exercise, attrs) do
    workout_template_exercise
    |> cast(attrs, [:workout_template_id, :exercise_id, :order, :target_sets, :target_reps])
    |> validate_required([:workout_template_id, :exercise_id, :order, :target_sets, :target_reps])
    |> validate_number(:order, greater_than: 0)
    |> validate_number(:target_sets, greater_than: 0, less_than_or_equal_to: 10)
    |> validate_number(:target_reps, greater_than: 0, less_than_or_equal_to: 50)
    |> foreign_key_constraint(:workout_template_id)
    |> foreign_key_constraint(:exercise_id)
    |> unique_constraint([:workout_template_id, :order])
  end
end

