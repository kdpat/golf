defmodule Golf.GamesTest do
  use Golf.DataCase

  alias Golf.{Games, GamesDb}
  alias Golf.Games.{Opts, Event}

  test "two player game" do
    user1 = Golf.AccountsFixtures.user_fixture()
    user2 = Golf.AccountsFixtures.user_fixture()

    id = Golf.gen_id()
    users = [user1, user2]
    opts = %Opts{num_rounds: 2}

    {:ok, game} = GamesDb.create_game(id, users, opts)

    p1 = Enum.at(game.players, 0)
    p2 = Enum.at(game.players, 1)

    assert Games.current_state(game) == :no_round
    refute Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    assert game == GamesDb.get_game(id)

    {:ok, game} = GamesDb.start_round(game)

    assert Games.current_state(game) == :flip_2
    assert Games.current_round(game).turn == 0
    assert Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    assert game == GamesDb.get_game(id)

    event = Event.new(game, p1, :flip, 0)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :flip_2
    assert Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    assert game == GamesDb.get_game(id)

    event = Event.new(game, p2, :flip, 5)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :flip_2
    assert Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    event = Event.new(game, p2, :flip, 4)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :flip_2
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :flip, 1)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :take
    assert Games.current_round(game).turn == 1
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :take_deck)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :hold
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :discard)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :flip
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :flip, 2)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :take
    refute Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    event = Event.new(game, p2, :take_table)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_round(game).turn == 2
    assert Games.current_state(game) == :hold
    refute Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    event = Event.new(game, p2, :swap, 3)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :take
    assert Games.current_round(game).turn == 3
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :take_deck)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :hold
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :discard)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :flip
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :flip, 3)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :take
    assert Games.current_round(game).turn == 4
    refute Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    event = Event.new(game, p2, :take_deck)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :hold
    refute Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    event = Event.new(game, p2, :swap, 2)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :take
    assert Games.current_round(game).turn == 5
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :take_table)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :hold
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :discard)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :flip
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :flip, 4)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :take
    refute Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    event = Event.new(game, p2, :take_deck)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :hold
    refute Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    # refute Games.current_round(game).flipped?

    event = Event.new(game, p2, :swap, 2)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :take
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :take_table)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :hold
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :swap, 5)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :take
    refute Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    # assert Games.current_round(game).flipped?
    # assert Games.current_round(game).turn == 8

    dbg(game.rounds |> List.first())
  end
end
