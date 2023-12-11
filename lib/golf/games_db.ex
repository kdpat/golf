defmodule Golf.GamesDb do
  import Ecto.Query, warn: false

  alias Golf.Repo
  alias Golf.Games
  alias Golf.Games.{Game, Event, Player, Round, Opts}

  @events_query from(e in Event, order_by: [desc: :id])
  @players_query from(p in Player, order_by: p.turn)
  @player_turn_query from(p in Player, select: %{turn: p.turn})
  @round_query from(r in Round, order_by: [desc: :id])

  @game_preloads [
    :opts,
    players: {@players_query, [:user]},
    rounds: {@round_query, [events: {@events_query, [player: @player_turn_query]}]}
  ]

  def get_game(id, preloads \\ @game_preloads) do
    Repo.get(Game, id)
    |> Repo.preload(preloads)
  end

  def game_exists?(id) do
    from(g in Game, where: [id: ^id])
    |> Repo.exists?()
  end

  def get_user_games(user_id) do
    from(p in Player,
      where: [user_id: ^user_id],
      join: g in Game,
      on: [id: p.game_id],
      order_by: g.inserted_at,
      select: g
    )
    |> Repo.all()
    |> Enum.map(&format_game_time/1)
  end

  defp format_game_time(game) do
    format = "%y/%m/%d %H:%m:%S"
    Map.update!(game, :inserted_at, &Calendar.strftime(&1, format))
  end

  def create_game(id, users, opts \\ Opts.default()) do
    Games.new_game(id, users, opts)
    |> insert_game()
  end

  defp insert_game(game) do
    game
    |> Game.changeset()
    |> Repo.insert()
  end

  def start_round(game) when length(game.rounds) >= game.opts.num_rounds do
    {:error, :max_rounds}
  end

  def start_round(game) do
    with {:ok, round} <- create_round(game) do
      {:ok, %Game{game | rounds: [round | game.rounds]}}
    end
  end

  defp create_round(game) do
    Games.new_round(game)
    |> Round.changeset()
    |> Repo.insert()
  end

  def handle_event(%Game{rounds: []}, _) do
    {:error, :no_round}
  end

  def handle_event(%Game{rounds: [%Round{state: :round_over} | _]}, _) do
    {:error, :round_over}
  end

  def handle_event(%Game{rounds: [round | _]} = game, event) do
    with {:ok, round} <- handle_round_event(round, event) do
      rounds = List.replace_at(game.rounds, 0, round)
      {:ok, %Game{game | rounds: rounds}}
    end
  end

  defp handle_round_event(round, event) do
    changes = Games.round_changes(round, event)
    update_round_event(round, event, changes)
  end

  defp update_round_event(round, event, round_changes) do
    Repo.transaction(fn ->
      {:ok, event} = insert_event(event)
      {:ok, round} = update_round(round, round_changes)
      event = Map.update!(event, :player, &%{turn: &1.turn})
      %Round{round | events: [event | round.events]}
    end)
  end

  defp insert_event(event) do
    event
    |> Event.changeset()
    |> Repo.insert()
  end

  defp update_round(round, changes) do
    round
    |> Round.changeset(changes)
    |> Repo.update()
  end
end
