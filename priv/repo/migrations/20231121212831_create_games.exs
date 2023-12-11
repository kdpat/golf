defmodule Golf.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games, primary_key: false) do
      add :id, :string, primary_key: true
      add :host_id, references(:users)
      timestamps(type: :utc_datetime)
    end

    create table(:opts) do
      add :game_id, references(:games, type: :string)
      add :num_rounds, :integer
    end

    create unique_index(:opts, [:game_id])

    create table(:players) do
      add :game_id, references(:games, type: :string)
      add :user_id, references(:users)
      add :turn, :integer
      timestamps(type: :utc_datetime)
    end

    create unique_index(:players, [:game_id, :user_id])
    create unique_index(:players, [:game_id, :turn])

    create table(:rounds) do
      add :game_id, references(:games, type: :string)
      add :state, :string
      add :flipped?, :boolean
      add :turn, :integer
      add :deck, {:array, :string}
      add :table_cards, {:array, :string}
      add :hands, {:array, {:array, :map}}
      add :held_card, :map
      timestamps(type: :utc_datetime)
    end

    create table(:events) do
      add :round_id, references(:rounds)
      add :player_id, references(:players)
      add :action, :string
      add :hand_index, :integer
      timestamps(type: :utc_datetime, updated_at: false)
    end
  end
end
