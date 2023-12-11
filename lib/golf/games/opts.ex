defmodule Golf.Games.Opts do
  use TypedEctoSchema
  import Ecto.Changeset

  typed_schema "opts" do
    field :num_rounds, :integer, default: 1, null: false
    belongs_to :game, Golf.Games.Game, type: :string
  end

  def changeset(opts, attrs \\ %{}) do
    opts
    |> cast(attrs, [:num_rounds])
    |> validate_required([:num_rounds])
  end

  def default(), do: %__MODULE__{num_rounds: 1}
end
