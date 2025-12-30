defmodule Strong4life.Repo.Migrations.CreateWorkoutSessions do
  use Ecto.Migration

  def change do
    create table(:workout_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :id, on_delete: :delete_all), null: false
      add :workout_template_id, references(:workout_templates, type: :binary_id, on_delete: :nilify_all)
      add :started_at, :utc_datetime, null: false
      add :completed_at, :utc_datetime
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:workout_sessions, [:user_id])
    create index(:workout_sessions, [:workout_template_id])
    create index(:workout_sessions, [:started_at])
  end
end
