defmodule Golf.Repo.Migrations.CreateChatMessagesTable do
  use Ecto.Migration

  def change do
    create table("chat_messages") do
      add :user_id, references("users")
      add :topic, :string
      add :content, :string, null: false
      timestamps(type: :utc_datetime)
    end
  end
end
