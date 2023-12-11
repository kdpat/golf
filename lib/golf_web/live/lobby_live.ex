defmodule GolfWeb.LobbyLive do
  use GolfWeb, :live_view
  import GolfWeb.Components, only: [players_list: 1, opts_form: 1, chat: 1]

  alias Golf.Chat
  alias Golf.Games.Opts

  @name_colors ~w(blue fuchsia green zinc)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-md space-y-12 divide-y text-center">
      <h1 class="leading-8 text-zinc-800 text-center">
        <div>
          <span class="text-lg font-bold">Lobby</span>
          <span class="text-green-500 text-4xl font-mono font-semibold copyable hover:cursor-pointer hover:underline"><%= @id %></span>
        </div>
      </h1>

      <.players_list users={@streams.users} colors={@name_colors} />

      <.chat messages={@streams.chat_messages} submit="submit-chat" />

      <.opts_form
        :if={@host? && !@game_exists?}
        num_rounds={@num_rounds}
        submit="start-game"
        change="change-num-rounds"
      />

      <.button :if={@game_exists?} phx-click="goto-game">Go To Game</.button>

      <p :if={@host? == false && !@game_exists?} class="text-center">
        Waiting for host to start game...
      </p>
    </div>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      send(self(), {:load_lobby, id})
      send(self(), {:load_game_exists?, id})
      send(self(), {:load_chat_messages, id})
    end

    {:ok,
     assign(socket,
       page_title: "Lobby",
       id: id,
       lobby: nil,
       num_rounds: 1,
       host?: nil,
       can_join?: nil,
       game_exists?: nil,
       name_colors: @name_colors,
       user_colors: %{}
     )
     |> stream(:users, [])
     |> stream(:chat_messages, [])}
  end

  @impl true
  def handle_info({:load_lobby, id}, socket) do
    case Golf.Lobbies.get_lobby(id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Lobby #{id} not found.")
         |> push_navigate(to: ~p"/")}

      lobby ->
        host? = lobby.host_id == socket.assigns.current_user.id

        user_colors =
          lobby.users
          |> Enum.zip_with(@name_colors, &{&1.id, &2})
          |> Enum.into(%{})

        lobby =
          Map.update!(lobby, :users, fn users ->
            users
            |> Enum.with_index()
            |> Enum.map(fn {user, i} ->
              color = Enum.at(@name_colors, i)
              Map.put(user, :color, color)
            end)
          end)

        :ok = Golf.subscribe("lobby:#{id}")

        {:noreply,
         socket
         |> assign(lobby: lobby, host?: host?, user_colors: user_colors)
         |> stream(:users, lobby.users)}
    end
  end

  @impl true
  def handle_info({:load_game_exists?, id}, socket) do
    {:noreply, assign(socket, game_exists?: Golf.GamesDb.game_exists?(id))}
  end

  @impl true
  def handle_info({:load_chat_messages, id}, socket) do
    messages =
      Golf.Chat.get_messages(id)
      |> Enum.map(fn msg ->
        color = Map.fetch!(socket.assigns.user_colors, msg.user_id)
        Map.put(msg, :color, color)
      end)

    :ok = Golf.subscribe("chat:#{id}")
    {:noreply, stream(socket, :chat_messages, messages, at: 0)}
  end

  @impl true
  def handle_info({:new_chat_message, message}, socket) do
    color = Map.fetch!(socket.assigns.user_colors, message.user_id)
    message = Map.put(message, :color, color)
    {:noreply, stream_insert(socket, :chat_messages, message, at: 0)}
  end

  @impl true
  def handle_info({:user_joined, lobby, new_user}, socket) do
    can_join? =
      if new_user.id == socket.assigns.current_user.id do
        false
      else
        socket.assigns.can_join?
      end

    color = Enum.at(@name_colors, length(lobby.users) - 1)
    new_user = Map.put(new_user, :color, color) |> dbg()
    user_colors = Map.put(socket.assigns.user_colors, new_user.id, color) |> dbg()

    {:noreply,
     socket
     |> assign(lobby: lobby, can_join?: can_join?, user_colors: user_colors)
     |> stream_insert(:users, new_user)
     |> put_flash(:info, "User joined: #{new_user.name}")}
  end

  @impl true
  def handle_info({:game_created, game}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/game/#{game.id}")}
  end

  @impl true
  def handle_event("change-num-rounds", %{"num-rounds" => num_rounds}, socket) do
    {:noreply, assign(socket, num_rounds: num_rounds)}
  end

  @impl true
  def handle_event("start-game", %{"num-rounds" => num_rounds}, socket) do
    id = socket.assigns.id

    unless socket.assigns.game_exists? do
      {num_rounds, _} = Integer.parse(num_rounds)
      opts = %Opts{num_rounds: num_rounds}
      {:ok, game} = Golf.GamesDb.create_game(id, socket.assigns.lobby.users, opts)
      :ok = Golf.broadcast("lobby:#{id}", {:game_created, game})
    end

    {:noreply, push_navigate(socket, to: ~p"/game/#{id}")}
  end

  @impl true
  def handle_event("goto-game", _, socket) do
    {:noreply, push_navigate(socket, to: ~p"/game/#{socket.assigns.id}")}
  end

  @impl true
  def handle_event("submit-chat", %{"content" => content}, socket) do
    id = socket.assigns.id

    {:ok, message} =
      Chat.Message.new(id, socket.assigns.current_user, content)
      |> Chat.insert_message()

    message =
      message
      |> Map.update!(:inserted_at, &Chat.format_chat_time/1)
      |> Map.put(:color, "blue")

    :ok = Golf.broadcast("chat:#{id}", {:new_chat_message, message})
    {:noreply, push_event(socket, "clear-chat-input", %{})}
  end
end
