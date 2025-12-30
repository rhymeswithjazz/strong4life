defmodule Strong4life.Workouts.Exercise do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "exercises" do
    field :name, :string
    field :category, :string
    field :instructions, :string
    field :default_sets, :integer, default: 3
    field :default_reps, :integer, default: 5
    field :is_accessory, :boolean, default: false

    has_many :workout_template_exercises, Strong4life.Workouts.WorkoutTemplateExercise
    has_many :workout_sets, Strong4life.Workouts.WorkoutSet

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(exercise, attrs) do
    exercise
    |> cast(attrs, [:name, :category, :instructions, :default_sets, :default_reps, :is_accessory])
    |> validate_required([:name, :category])
    |> unique_constraint(:name)
    |> validate_inclusion(:category, ["compound", "accessory"])
    |> validate_number(:default_sets, greater_than: 0, less_than_or_equal_to: 10)
    |> validate_number(:default_reps, greater_than: 0, less_than_or_equal_to: 50)
  end
end

