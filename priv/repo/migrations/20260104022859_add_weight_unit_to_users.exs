defmodule Strong4life.Repo.Migrations.AddWeightUnitToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :weight_unit, :string, default: "lbs", null: false
    end
  end
end
