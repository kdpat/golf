defmodule Golf.Games do
  alias Golf.Games.{Game, Player, Opts, Round, Event}

  @card_names for rank <- ~w(A 2 3 4 5 6 7 8 9 T J Q K),
                  suit <- ~w(C D H S),
                  do: rank <> suit

  @num_decks 2
  @hand_size 6

  defp new_deck(1), do: @card_names

  defp new_deck(n) when n > 1 do
    @card_names ++ new_deck(n - 1)
  end

  defp deal_from([], _) do
    {:error, :empty_deck}
  end

  defp deal_from(deck, n) when length(deck) < n do
    {:error, :not_enough_cards}
  end

  defp deal_from(deck, n) do
    {cards, deck} = Enum.split(deck, n)
    {:ok, cards, deck}
  end

  defp deal_from(deck) do
    with {:ok, [card], deck} <- deal_from(deck, 1) do
      {:ok, card, deck}
    end
  end

  defp player_from({user, i}) do
    %Player{turn: i, user_id: user.id, user: user}
  end

  @spec new_game(binary, list(Golf.Accounts.User.t), Opts.t) :: term
  def new_game(id, [host | _] = users, opts \\ Opts.default()) do
    players =
      Enum.with_index(users)
      |> Enum.map(&player_from/1)

    %Game{
      id: id,
      host_id: host.id,
      opts: opts,
      players: players,
      rounds: []
    }
  end

  defp next_first_player_id(game) do
    case game.rounds do
      [] ->
        List.first(game.players).id

      [round | _] ->
        last_index = Enum.find_index(game.players, & &1.id == round.first_player_id)
        index = rem(last_index + 1, length(game.players))
        Enum.at(game.players, index).id
    end
  end

  @spec new_round(Game.t) :: Round.t
  def new_round(game) do
    jokers = List.duplicate("jk", @num_decks * 2)
    deck = Enum.shuffle(new_deck(@num_decks) ++ jokers)
    num_hand_cards = @hand_size * length(game.players)

    {:ok, hand_cards, deck} = deal_from(deck, num_hand_cards)
    {:ok, table_card, deck} = deal_from(deck)

    hands =
      hand_cards
      |> Enum.map(&%{"name" => &1, "face_up?" => false})
      |> Enum.chunk_every(@hand_size)

    %Round{
      game_id: game.id,
      state: :flip_2,
      turn: 0,
      deck: deck,
      hands: hands,
      table_cards: [table_card],
      events: [],
      first_player_id: next_first_player_id(game)
    }
  end

  @spec current_round(Game.t) :: Round.t | nil
  def current_round(%Game{rounds: [round | _]}), do: round
  def current_round(_), do: nil

  @spec current_state(Game.t) :: :no_round | :flip_2 | :take | :hold | :flip | :round_over | :game_over
  def current_state(%Game{rounds: [round | _]} = game)
      when round.state == :round_over and length(game.rounds) >= game.opts.num_rounds do
    :game_over
  end

  def current_state(%Game{rounds: []}), do: :no_round
  def current_state(%Game{rounds: [round | _]}), do: round.state

  @spec can_act?(Game.t, Player.t) :: boolean
  def can_act?(%Game{rounds: []}, _), do: false

  def can_act?(%Game{rounds: [round | _]} = game, player) do
    can_act_round?(round, game.players, player)
  end

  def can_act_round?(%Round{state: :round_over}, _, _), do: false

  def can_act_round?(%Round{state: :flip_2} = round, _, player) do
    hand = Enum.at(round.hands, player.turn)
    num_cards_face_up(hand) < 2
  end

  def can_act_round?(round, players, player) do
    first_player_index = Enum.find_index(players, & &1.id == round.first_player_id)
    player_index = Enum.find_index(players, & &1.id == player.id)
    num_players = length(players)
    rem(round.turn-1, num_players) == Integer.mod(player_index-first_player_index, num_players)
  end

  def round_changes(%Round{state: :flip_2} = round, %Event{action: :flip} = event) do
    hands =
      List.update_at(
        round.hands,
        event.player.turn,
        &flip_card_at(&1, event.hand_index)
      )

    {state, turn} =
      if Enum.all?(hands, &min_two_face_up?/1) do
        {:take, round.turn + 1}
      else
        {:flip_2, round.turn}
      end

    %{state: state, hands: hands, turn: turn}
  end

  def round_changes(%Round{state: :flip} = round, %Event{action: :flip} = event) do
    hand =
      round.hands
      |> Enum.at(event.player.turn)
      |> flip_card_at(event.hand_index)

    hands = List.replace_at(round.hands, event.player.turn, hand)

    {state, turn, player_out_id} =
      cond do
        Enum.all?(hands, &all_face_up?/1) ->
          {:round_over, round.turn, round.player_out_id}

        all_face_up?(hand) ->
          {:take, round.turn + 1, round.player_out_id || event.player_id}

        true ->
          {:take, round.turn + 1, round.player_out_id}
      end

    %{state: state, turn: turn, hands: hands, player_out_id: player_out_id}
  end

  def round_changes(%Round{state: :take} = round, %Event{action: :take_deck} = event) do
    {:ok, card, deck} = deal_from(round.deck)

    %{
      state: :hold,
      deck: deck,
      held_card: %{"player_id" => event.player.id, "name" => card}
    }
  end

  def round_changes(%Round{state: :take} = round, %Event{action: :take_table} = event) do
    [card | table_cards] = round.table_cards

    %{
      state: :hold,
      table_cards: table_cards,
      held_card: %{"player_id" => event.player.id, "name" => card}
    }
  end

  def round_changes(
        %Round{state: :hold} = round,
        %Event{action: :discard} = event
      ) when is_integer(round.player_out_id) do
    hands = List.update_at(round.hands, event.player.turn, &flip_all/1)

    {state, turn} =
      if Enum.all?(hands, &all_face_up?/1) do
        {:round_over, round.turn}
      else
        {:take, round.turn + 1}
      end

    %{
      state: state,
      turn: turn,
      hands: hands,
      held_card: nil,
      table_cards: [round.held_card["name"] | round.table_cards]
    }
  end

  def round_changes(
        %Round{state: :hold} = round,
        %Event{action: :discard} = event
      ) when is_nil(round.player_out_id) do
    hand = Enum.at(round.hands, event.player.turn)

    {state, turn, player_out_id} =
      cond do
        # TODO handle player going out early
        one_face_down?(hand) ->
          {:take, round.turn + 1, round.player_out_id}

        true ->
          {:flip, round.turn, round.player_out_id}
      end

    %{
      state: state,
      turn: turn,
      held_card: nil,
      table_cards: [round.held_card["name"] | round.table_cards],
      player_out_id: player_out_id
    }
  end

  def round_changes(
        %Round{state: :hold} = round,
        %Event{action: :swap} = event
      ) do
    {hand, card} =
      round.hands
      |> Enum.at(event.player.turn)
      |> flip_all_if(is_integer(round.player_out_id))
      |> swap_card(event.hand_index, round.held_card["name"])

    hands = List.replace_at(round.hands, event.player.turn, hand)

    {state, turn, player_out_id} =
      cond do
        Enum.all?(hands, &all_face_up?/1) ->
          {:round_over, round.turn, round.player_out_id || event.player_id}

        all_face_up?(hand) ->
          {:take, round.turn + 1, round.player_out_id || event.player_id}

        true ->
          {:take, round.turn + 1, round.player_out_id}
      end

    %{
      state: state,
      turn: turn,
      held_card: nil,
      hands: hands,
      table_cards: [card | round.table_cards],
      player_out_id: player_out_id
    }
  end

  def playable_cards(%Round{state: :flip_2} = round, _, player) do
    hand = Enum.at(round.hands, player.turn)

    if num_cards_face_up(hand) < 2 do
      face_down_cards(hand)
    else
      []
    end
  end

  def playable_cards(round, players, player) do
    if can_act_round?(round, players, player) do
      hand = Enum.at(round.hands, player.turn)
      card_places(round.state, is_integer(round.player_out_id), hand)
    else
      []
    end
  end

  defp card_places(_state, _flipped?, _hand)
  defp card_places(:take, true, hand), do: [:deck, :table] ++ face_down_cards(hand)
  defp card_places(:take, false, _), do: [:deck, :table]
  defp card_places(:flip, _, hand), do: face_down_cards(hand)
  defp card_places(:hold, _, _), do: [:held, :hand_0, :hand_1, :hand_2, :hand_3, :hand_4, :hand_5]

  @spec score(map) :: integer
  def score(hand) do
    hand
    |> Enum.map(&rank_if_face_up/1)
    |> score_ranks(0)
  end

  # "AS" -> ace of spades, "KH" -> king of hearts etc.
  # The rank is the first char of the name. rank "AS" -> ?A
  # rank_if_face_up?(%{"face_up" => true, "name" => "AS"}) == ?A
  defp rank_if_face_up(%{"face_up?" => true, "name" => <<rank, _>>}), do: rank
  defp rank_if_face_up(_), do: nil

  defp rank_value(rank) when is_integer(rank) do
    case rank do
      ?j -> -2 # joker
      ?K -> 0
      ?A -> 1
      ?2 -> 2
      ?3 -> 3
      ?4 -> 4
      ?5 -> 5
      ?6 -> 6
      ?7 -> 7
      ?8 -> 8
      ?9 -> 9
      r when r in [?T, ?J, ?Q] -> 10
    end
  end

  # Each hand consists of two rows of three cards.
  # Face down cards are represented by nil and ignored.
  # If the cards are face up and in a matching column, they are worth 0 points and discarded.

  # Special cases:
  #   6 of a kind -> -40 pts
  #   4 of a kind (outer cols) -> -20 pts
  #   4 of a kind (adjacent cols) -> -10 pts

  # The rank value of each remaining face up card is totaled together.
  defp score_ranks(ranks, total) do
    case ranks do
      # all match, -40 points
      [a, a, a,
       a, a, a] when is_integer(a) ->
        -40

      [?j, b, ?j,
       ?j, c, ?j] ->
        score_ranks([b, c], -28)

      # outer cols match, -20 points
      [a, b, a,
       a, c, a] when is_integer(a) ->
        score_ranks([b, c], total - 20)

      [?j, ?j, a,
       ?j, ?j, b] ->
        score_ranks([a, b], total - 18)

      # left 2 cols match, -10 points
      [a, a, b,
       a, a, c] when is_integer(a) ->
        score_ranks([b, c], total - 10)

      [a, ?j, ?j,
       b, ?j, ?j] ->
        score_ranks([a, b], total - 18)

      # right 2 cols match, -10 points
      [a, b, b,
       c, b, b] when is_integer(b) ->
        score_ranks([a, c], total - 10)

      [?j, b, c,
       ?j, d, e] ->
        score_ranks([b, c, d, e], total - 4)

      # left col match
      [a, b, c,
       a, d, e] when is_integer(a) ->
        score_ranks([b, c, d, e], total)

      [a, ?j, c,
       d, ?j, e] ->
        score_ranks([a, c, d, e], total - 4)

      # middle col match
      [a, b, c,
       d, b, e] when is_integer(b) ->
        score_ranks([a, c, d, e], total)

      [a, b, ?j,
       d, e, ?j] ->
        score_ranks([a, b, d, e], total - 4)

      # right col match
      [a, b, c,
       d, e, c] when is_integer(c) ->
        score_ranks([a, b, d, e], total)

      [?j, b,
       ?j, c] ->
        score_ranks([b, c], total - 4)

      # left col match, pass 2
      [a, b,
       a, c] when is_integer(a) ->
        score_ranks([b, c], total)

      [a, ?j,
       c, ?j] ->
        score_ranks([a, c], total - 4)

      # right col match, pass 2
      [a, b,
       c, b] when is_integer(b) ->
        score_ranks([a, c], total)

      [?j,
       ?j] ->
        total - 4

      # match, pass 3
      [a,
       a] when is_integer(a) ->
        total

      # no matches, add the rank val of each face up card to the total
      _ ->
        ranks
        |> Enum.reject(&is_nil/1)
        |> Enum.reduce(total, fn rank, acc -> rank_value(rank) + acc end)
    end
  end

  defp flip_card(card) do
    %{card | "face_up?" => true}
  end

  defp flip_card_at(hand, index) do
    List.update_at(hand, index, &flip_card/1)
  end

  defp flip_all(hand) do
    Enum.map(hand, &flip_card/1)
  end

  defp flip_all_if(hand, true), do: flip_all(hand)
  defp flip_all_if(hand, _), do: hand

  defp swap_card(hand, index, new_card) do
    old_card = Enum.at(hand, index)["name"]
    hand = List.replace_at(hand, index, %{"name" => new_card, "face_up?" => true})
    {hand, old_card}
  end

  defp num_cards_face_up(hand) do
    Enum.count(hand, & &1["face_up?"])
  end

  defp all_face_up?(hand) do
    num_cards_face_up(hand) == @hand_size
  end

  defp one_face_down?(hand) do
    num_cards_face_up(hand) == @hand_size - 1
  end

  defp min_two_face_up?(hand) do
    num_cards_face_up(hand) >= 2
  end

  defp face_down_cards(hand) do
    hand
    |> Enum.with_index()
    |> Enum.reject(fn {card, _} -> card["face_up?"] end)
    |> Enum.map(fn {_, index} -> String.to_existing_atom("hand_#{index}") end)
  end

  def game_stats(game, colors) do
    game
    |> Map.put(:state, current_state(game))
    |> Map.update!(:rounds, fn rounds ->
        round_nums = length(game.rounds)..1
        Enum.zip_with(rounds, round_nums, &round_stats(&1, &2, game.players, colors))
      end
    )
    |> Map.put(:totals, total_scores(game, colors))
  end

  def total_scores(game, colors) do
    game.players
    |> Enum.zip_with(colors, fn p, c -> Map.put(p, :color, c) end)
    |> Enum.map(fn p -> {p.user.name, p.color, total_scores_player(game, p.id)} end)
    |> Enum.sort_by(fn {_, _, score} -> score end)
  end

  def total_scores_player(game, player_id) do
    index = Enum.find_index(game.players, & &1.id == player_id)

    Enum.reduce(game.rounds, 0, fn round, total ->
      hand = Enum.at(round.hands, index)

      score =
        if player_set?(round, game.players, player_id) do
          score = score(hand)

          # only double the score if it's positive
          if score < 0 do
            score
          else
            score * 2
          end
        else
          score(hand)
        end

      total + score
    end)
  end

  def player_set?(round, players, player_id) do
    if round.state == :round_over and round.player_out_id == player_id do
      index = Enum.find_index(players, & &1.id == player_id)
      any_lower_score?(round.hands, index)
    else
      false
    end
  end

  defp round_stats(round, round_num, players, colors) do
    out_index = Enum.find_index(players, & &1.id == round.player_out_id)

    player_out = if out_index do
      Enum.at(players, out_index)
      |> Map.put(:score, Enum.at(round.hands, out_index) |> score())
    end

    players =
      players
      |> put_raw_scores(round.hands)
      |> Enum.zip_with(colors, fn p, c -> Map.put(p, :color, c) end)

    players =
      # if the player who went out first lost, double their score (if the score is positive)
      if round.state == :round_over && out_index && any_lower_score?(round.hands, out_index) do
        Enum.map(players, fn p ->
          if p.id == player_out.id do
            Map.update!(p, :score, fn n ->
              if n > 0 do
                n * 2
              else
                n
              end
            end)
          end
        end)
      else
        players
      end

    players = Enum.sort_by(players, & &1.score)

    %{
      id: round.id,
      num: round_num,
      state: round.state,
      turn: round.turn,
      players: players,
      player_out_username: player_out && player_out.user.name
    }
  end

  def any_lower_score?(hands, index) do
    score = score(Enum.at(hands, index))
    Enum.any?(hands, &(score(&1) < score))
  end

  defp put_raw_scores(players, []) do
    Enum.map(players, &Map.put(&1, :score, 0))
  end

  defp put_raw_scores(players, hands) do
    Enum.zip_with(players, hands, fn p, hand ->
      Map.put(p, :score, score(hand))
    end)
  end
end
