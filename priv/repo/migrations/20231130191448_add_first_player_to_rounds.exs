defmodule Golf.Repo.Migrations.AddFirstPlayerToRounds do
  use Ecto.Migration

  def change do
    rename table(:rounds), :player_out, to: :player_out_id

    alter table(:rounds) do
      add :first_player_id, references(:players)
    end
  end
end
