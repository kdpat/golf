defmodule Golf.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_messages" do
    belongs_to :user, Golf.Accounts.User
    field :topic, :string
    field :content, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(message, attrs \\ %{}) do
    message
    |> cast(attrs, [:user_id, :topic, :content])
    |> validate_required([:user_id, :topic, :content])
  end

  def new(topic, user, content) do
    %__MODULE__{
      topic: topic,
      content: content,
      user_id: user.id,
      user: user
    }
  end
end
