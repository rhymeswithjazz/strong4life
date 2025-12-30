defmodule Strong4life.Repo.Migrations.CreateWorkoutTemplateExercises do
  use Ecto.Migration

  def change do
    create table(:workout_template_exercises, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :workout_template_id,
          references(:workout_templates, type: :binary_id, on_delete: :delete_all),
          null: false

      add :exercise_id, references(:exercises, type: :binary_id, on_delete: :delete_all),
        null: false

      add :order, :integer, null: false
      add :target_sets, :integer, null: false
      add :target_reps, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:workout_template_exercises, [:workout_template_id])
    create index(:workout_template_exercises, [:exercise_id])
    create unique_index(:workout_template_exercises, [:workout_template_id, :order])
  end
end
