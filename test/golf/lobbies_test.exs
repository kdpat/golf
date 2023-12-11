defmodule Golf.LobbiesTest do
  # use Golf.DataCase

  # alias Golf.Lobbies

  # describe "lobbies" do
  #   alias Golf.Lobbies.Lobby

  #   import Golf.LobbiesFixtures

  #   @invalid_attrs %{id: nil}

  #   test "list_lobbies/0 returns all lobbies" do
  #     lobby = lobby_fixture()
  #     assert Lobbies.list_lobbies() == [lobby]
  #   end

  #   test "get_lobby!/1 returns the lobby with given id" do
  #     lobby = lobby_fixture()
  #     assert Lobbies.get_lobby!(lobby.id) == lobby
  #   end

  #   test "create_lobby/1 with valid data creates a lobby" do
  #     valid_attrs = %{id: "some id"}

  #     assert {:ok, %Lobby{} = lobby} = Lobbies.create_lobby(valid_attrs)
  #     assert lobby.id == "some id"
  #   end

  #   test "create_lobby/1 with invalid data returns error changeset" do
  #     assert {:error, %Ecto.Changeset{}} = Lobbies.create_lobby(@invalid_attrs)
  #   end

  #   test "update_lobby/2 with valid data updates the lobby" do
  #     lobby = lobby_fixture()
  #     update_attrs = %{id: "some updated id"}

  #     assert {:ok, %Lobby{} = lobby} = Lobbies.update_lobby(lobby, update_attrs)
  #     assert lobby.id == "some updated id"
  #   end

  #   test "update_lobby/2 with invalid data returns error changeset" do
  #     lobby = lobby_fixture()
  #     assert {:error, %Ecto.Changeset{}} = Lobbies.update_lobby(lobby, @invalid_attrs)
  #     assert lobby == Lobbies.get_lobby!(lobby.id)
  #   end

  #   test "delete_lobby/1 deletes the lobby" do
  #     lobby = lobby_fixture()
  #     assert {:ok, %Lobby{}} = Lobbies.delete_lobby(lobby)
  #     assert_raise Ecto.NoResultsError, fn -> Lobbies.get_lobby!(lobby.id) end
  #   end

  #   test "change_lobby/1 returns a lobby changeset" do
  #     lobby = lobby_fixture()
  #     assert %Ecto.Changeset{} = Lobbies.change_lobby(lobby)
  #   end
  # end
end
