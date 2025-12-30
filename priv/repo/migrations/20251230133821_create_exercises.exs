defmodule Strong4life.Repo.Migrations.CreateExercises do
  use Ecto.Migration

  def change do
    create table(:exercises, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :category, :string, null: false
      add :instructions, :text
      add :default_sets, :integer, default: 3
      add :default_reps, :integer, default: 5
      add :is_accessory, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:exercises, [:name])
    create index(:exercises, [:category])
  end
end
