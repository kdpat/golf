defmodule Golf.Lobbies.LobbyUser do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "lobbies_users" do
    belongs_to :lobby, Golf.Lobbies.Lobby, type: :string
    belongs_to :user, Golf.Accounts.User
    timestamps(type: :utc_datetime)
  end

  def changeset(lobby_user, attrs \\ %{}) do
    lobby_user
    |> cast(attrs, [:lobby_id, :user_id])
    |> validate_required([:lobby_id, :user_id])
  end
end
