defmodule Strong4life.Workouts.WorkoutTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "workout_templates" do
    field :name, :string
    field :description, :string

    has_many :workout_template_exercises, Strong4life.Workouts.WorkoutTemplateExercise
    has_many :exercises, through: [:workout_template_exercises, :exercise]
    has_many :workout_sessions, Strong4life.Workouts.WorkoutSession

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout_template, attrs) do
    workout_template
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end

