defmodule Golf.Games.Round do
  # use Ecto.Schema
  use TypedEctoSchema
  import Ecto.Changeset

  @states [:flip_2, :take, :hold, :flip, :round_over]

  typed_schema "rounds" do
    field :state, Ecto.Enum, values: @states
    field :turn, :integer
    field :deck, {:array, :string}, default: []
    field :table_cards, {:array, :string}, default: []
    field :hands, {:array, {:array, :map}}, default: []
    field :held_card, :map

    belongs_to :game, Golf.Games.Game, type: :string
    belongs_to :player_out, Golf.Games.Player
    belongs_to :first_player, Golf.Games.Player

    has_many :events, Golf.Games.Event

    timestamps(type: :utc_datetime)
  end

  def changeset(round, attrs \\ %{}) do
    round
    |> cast(attrs, [
      :game_id,
      :state,
      :turn,
      :deck,
      :table_cards,
      :hands,
      :held_card,
      :player_out_id,
      :first_player_id
    ])
    |> validate_required([:game_id, :state, :turn, :deck, :table_cards, :hands, :first_player_id])
  end
end
