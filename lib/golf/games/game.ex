defmodule Golf.Games.Game do
  use TypedEctoSchema
  import Ecto.Changeset

  @primary_key {:id, :string, []}

  @states [:no_round, :flip_2, :take, :hold, :flip, :round_over, :game_over]

  typed_schema "games" do
    belongs_to :host, Golf.Accounts.User
    has_many :players, Golf.Games.Player
    has_many :rounds, Golf.Games.Round
    has_one :opts, Golf.Games.Opts

    field :state, Ecto.Enum, values: @states, virtual: true

    timestamps(type: :utc_datetime)
  end

  def changeset(game, attrs \\ %{}) do
    game
    |> cast(attrs, [:id, :host_id])
    |> validate_required([:id, :host_id])
  end
end
