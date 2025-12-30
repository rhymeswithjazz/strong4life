defmodule Strong4life.Repo.Migrations.CreateWorkoutSets do
  use Ecto.Migration

  def change do
    create table(:workout_sets, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :workout_session_id,
          references(:workout_sessions, type: :binary_id, on_delete: :delete_all), null: false

      add :exercise_id, references(:exercises, type: :binary_id, on_delete: :delete_all),
        null: false

      add :set_number, :integer, null: false
      add :weight, :decimal, precision: 6, scale: 2
      add :reps, :integer
      add :rpe, :integer
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:workout_sets, [:workout_session_id])
    create index(:workout_sets, [:exercise_id])
    create unique_index(:workout_sets, [:workout_session_id, :exercise_id, :set_number])
  end
end
