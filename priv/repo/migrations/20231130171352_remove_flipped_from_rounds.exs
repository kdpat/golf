defmodule Golf.Repo.Migrations.RemoveFlippedFromRounds do
  use Ecto.Migration

  def change do
    alter table(:rounds) do
      remove :flipped?
    end
  end
end
