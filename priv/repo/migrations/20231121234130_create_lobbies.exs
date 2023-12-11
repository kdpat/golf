defmodule Golf.Repo.Migrations.CreateLobbies do
  use Ecto.Migration

  def change do
    create table(:lobbies, primary_key: false) do
      add :id, :string, primary_key: true
      add :host_id, references(:users)
      timestamps(type: :utc_datetime)
    end

    create table(:lobbies_users, primary_key: false) do
      add :lobby_id, references(:lobbies, type: :string)
      add :user_id, references(:users)
      timestamps(type: :utc_datetime)
    end

    create unique_index(:lobbies_users, [:lobby_id, :user_id])
  end
end
