defmodule GolfWeb.Components do
  use Phoenix.Component
  import GolfWeb.CoreComponents

  def join_lobby_form(assigns) do
    ~H"""
    <form phx-submit={@submit} class="w-1/4 mx-auto">
      <.input name="id" value="" placeholder="Game ID" required />
      <.button class="w-full">Join Game</.button>
    </form>
    """
  end

  def players_list(assigns) do
    ~H"""
    <div class="flex-none w-1/2 mx-auto">
      <h4 class="font-semibold text-md">Players</h4>
      <ol id="players-list" phx-update="stream" class="p-2">
        <li :for={{dom_id, user} <- @users} id={dom_id}>
          <span class={"text-#{user.color}-500 font-semibold"}>
            <%= user.name %>
          </span>
        </li>
      </ol>
    </div>
    """
  end

  def opts_form(assigns) do
    ~H"""
    <div class="w-1/2 mx-auto">
      <h4 class="font-semibold text-md">Settings</h4>
      <form phx-submit={@submit} phx-change={@change} class="space-y-1">
        <.input
          name="num-rounds"
          type="number"
          min="1"
          max="32"
          label="Number of rounds"
          pattern="\d*"
          value={@num_rounds}
          required
        />
        <.button>Start Game</.button>
      </form>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :messages, :list, default: []
  attr :submit, :any

  def chat(assigns) do
    ~H"""
    <div class={@class}>
      <.chat_messages messages={@messages} />
      <.chat_form class="mt-auto" submit={@submit} />
    </div>
    """
  end

  def chat_messages(assigns) do
    ~H"""
    <div class="h-full">
      <h4 class="font-semibold text-md mb-1 text-center">Messages</h4>
      <ul
        id="chat-messages"
        phx-update="stream"
        class="overflow-y-auto overflow-x-auto h-full max-h-[50vh] bg-slate-50 rounded-lg space-y-2"
      >
        <.chat_message :for={{id, msg} <- @messages} id={id} msg={msg} />
      </ul>
    </div>
    """
  end

  defp chat_message(assigns) do
    ~H"""
    <li id={@id} class="text-left whitespace-normal">
      <span class="text-xs text-green-600"><%= @msg.inserted_at %></span>
      <span class={"font-semibold text-sm text-#{@msg.color}-500"}><%= @msg.user.name %></span>:
      <p class="text-md"><%= @msg.content %></p>
    </li>
    """
  end

  def chat_form(assigns) do
    ~H"""
    <form phx-submit={@submit} class={["space-y-1", @class]}>
      <.input
        id="chat-form-input"
        name="content"
        value=""
        placeholder="Type chat message here..."
        required
      />
      <.button>Submit</.button>
    </form>
    """
  end

  def game_stats(assigns) do
    ~H"""
    <div class={["flex flex-col my-1", @class]}>
      <div class="mb-2">
        <h4 class="font-semibold mb-1 text-center">Total Scores</h4>
        <.total_scores_table totals={@stats.totals} />
      </div>

      <h4 class="font-semibold text-center">Rounds</h4>
      <.round_stats_table
        :for={round <- @stats.rounds}
        num={round.num}
        turn={round.turn}
        state={round.state}
        players={round.players}
        out_username={round.player_out_username}
      />
    </div>
    """
  end

  def total_scores_table(assigns) do
    ~H"""
    <table class="min-w-[50%] mx-auto table-fixed border-separate border rounded bg-slate-50">
      <thead class="text-sm text-center">
        <tr>
          <th :for={{username, color, _} <- @totals} class={"text-#{color}-500"}>
            <%= username %>
          </th>
        </tr>
      </thead>
      <tbody class="text-center text-sm">
        <tr>
          <td :for={{_, _, score} <- @totals} class="text-lg"><%= score %></td>
        </tr>
      </tbody>
    </table>
    """
  end

  def round_stats_table(assigns) do
    ~H"""
    <table class="table-auto border-separate border-spacing-1 border border-slate-200 px-2 rounded bg-slate-50">
      <thead class="text-xs text-left">
        <tr>
          <th>Round</th>
          <th>Scores</th>
          <th>Turns</th>
          <th>1st Out</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><%= @num %></td>
          <td><.players_stats players={@players} /></td>
          <td><%= @turn %></td>
          <td><%= @out_username %></td>
        </tr>
      </tbody>
    </table>
    """
  end

  def players_stats(assigns) do
    ~H"""
    <ol>
      <.player_stats :for={p <- @players} name={p.user.name} score={p.score} color={p.color} />
    </ol>
    """
  end

  def player_stats(assigns) do
    ~H"""
    <li>
      <span class={"font-semibold text-#{@color}-500"}><%= @name %></span>:
      <span class="text-green-600"><%= @score %></span>
    </li>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def game_button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "uppercase outline outline-black outline-1",
        "phx-submit-loading:opacity-75 rounded-lg bg-blue-500 hover:bg-blue-600 py-3 px-4",
        "font-bold text-white active:text-white/80 drop-shadow-lg border-solid",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  # adapted from https://flowbite.com/docs/forms/toggle/
  def info_switch(assigns) do
    ~H"""
    <label
      id="info-switch"
      class="top-[95%] left-[98%] translate-x-[-100%] absolute inline-flex items-center cursor-pointer"
    >
      <input
        checked={not @show_info?}
        phx-click="toggle-info"
        id="info-toggle"
        type="checkbox"
        value=""
        class="sr-only peer"
      />
      <div class="w-10 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 dark:peer-focus:ring-blue-800 rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-blue-600">
      </div>
      <span class="ms-2 text-sm font-medium text-gray-900 dark:text-gray-300">Hide</span>
    </label>
    """
  end
end
