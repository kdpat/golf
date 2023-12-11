defmodule Golf.Lobbies do
  import Ecto.Query, warn: false

  alias Golf.Repo
  alias Golf.Accounts.User
  alias Golf.Lobbies.{Lobby, LobbyUser}

  @max_players 4

  @doc """
  Sorts users by the time they joined the lobby.
  """
  def lobby_users_query(lobby_id) do
    from(u in User,
      join: lu in LobbyUser,
      on: u.id == lu.user_id,
      where: ^lobby_id == lu.lobby_id,
      order_by: lu.inserted_at,
      select: u
    )
  end

  def get_lobby(id) do
    Repo.get(Lobby, id)
    |> Repo.preload(users: lobby_users_query(id))
  end

  def create_lobby(id, host) do
    %Lobby{id: id, host_id: host.id, users: [host]}
    |> Lobby.changeset()
    |> Repo.insert()
  end

  def insert_lobby_user(lobby, user) do
    %LobbyUser{lobby_id: lobby.id, user_id: user.id}
    |> LobbyUser.changeset()
    |> Repo.insert()
  end

  def add_lobby_user(lobby, _) when length(lobby.users) >= @max_players do
    {:error, :max_players}
  end

  def add_lobby_user(lobby, user) do
    if Enum.any?(lobby.users, &(&1.id == user.id)) do
      {:error, :already_joined}
    else
      with {:ok, _} <- insert_lobby_user(lobby, user) do
        {:ok, %Lobby{lobby | users: lobby.users ++ [user]}}
      end
    end
  end
end
