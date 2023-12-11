defmodule Golf.Games.ClientData do
  @derive Jason.Encoder
  defstruct [
    :id,
    :hostId,
    :turn,
    :state,
    :isFlipped,
    :deck,
    :tableCards,
    :players,
    :playerId,
    :playableCards,
    :roundNum,
    :firstPlayerId
  ]

  def from(game, user) do
    index = Enum.find_index(game.players, &(&1.user_id == user.id))
    player = if index, do: Enum.at(game.players, index)

    num_players = length(game.players)
    positions = player_positions(num_players)

    round = Golf.Games.current_round(game)
    held_card = if round, do: round.held_card

    playable_cards =
      if player && round do
        Golf.Games.playable_cards(round, game.players, player)
      else
        []
      end

    players =
      game.players
      |> put_hands((round && round.hands) || [])
      |> maybe_rotate(index)
      |> Enum.zip_with(positions, &put_position/2)
      |> Enum.map(&put_player_data(&1, game, held_card))

    out_index = if round, do: Enum.find_index(players, fn p -> p.id == round.player_out_id end)

    player_out =
      if out_index do
        Enum.at(players, out_index)
        |> Map.put(
          :score,
          Enum.at(maybe_rotate(round.hands, index), out_index) |> Golf.Games.score()
        )
      end

    players =
      if round && round.player_out &&
           Golf.Games.player_set?(round, game.players, round.player_out_id) do
        Enum.map(players, fn p -> Golf.Games.double_score_if(p, p.id == player_out.id) end)
      else
        players
      end

    %__MODULE__{
      id: game.id,
      hostId: game.host_id,
      turn: (round && round.turn) || 0,
      state: Golf.Games.current_state(game),
      isFlipped: round && round.player_out_id,
      deck: (round && round.deck) || [],
      tableCards: (round && round.table_cards) || [],
      players: players,
      playerId: player && player.id,
      playableCards: playable_cards,
      roundNum: length(game.rounds),
      firstPlayerId: round && round.first_player_id
    }
  end

  defp player_positions(num_players) do
    case num_players do
      1 -> ~w(bottom)
      2 -> ~w(bottom top)
      3 -> ~w(bottom left right)
      4 -> ~w(bottom left top right)
    end
  end

  defp put_player_data(player, game, held_card) do
    player
    |> Map.put(:username, player.user.name)
    |> Map.put(:canAct, Golf.Games.can_act?(game, player))
    |> put_held_card(held_card)
  end

  defp put_held_card(p, %{"player_id" => card_pid} = card) when p.id == card_pid do
    %{p | heldCard: card["name"]}
  end

  defp put_held_card(player, _), do: player

  defp put_position(player, pos) do
    %{player | position: pos}
  end

  defp put_hands(players, []) do
    Enum.map(players, fn p -> %{p | hand: [], score: 0} end)
  end

  defp put_hands(players, hands) do
    Enum.zip_with(players, hands, fn p, hand ->
      %{p | hand: hand, score: Golf.Games.score(hand)}
    end)
  end

  def maybe_rotate(list, n) when n in [0, nil], do: list
  def maybe_rotate(list, n), do: Golf.rotate(list, n)
end
