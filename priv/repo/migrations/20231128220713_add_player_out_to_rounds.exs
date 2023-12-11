defmodule Golf.Repo.Migrations.AddPlayerOutToRounds do
  use Ecto.Migration

  def change do
    alter table(:rounds) do
      add :player_out, references(:players)
    end
  end
end
