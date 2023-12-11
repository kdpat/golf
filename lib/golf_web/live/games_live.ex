defmodule GolfWeb.GamesLive do
  use GolfWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-md space-y-6">
      <.header class="text-center">Games</.header>

      <div class="overflow-y-auto max-h-[600px]">
        <table class="w-full mx-auto bg-slate-100">
          <thead class="sticky top-0 bg-white text-center leading-6 text-zinc-500">
            <tr class="">
              <th class="pb-1.5">Game ID</th>
              <th class="pb-1.5">Created At</th>
            </tr>
          </thead>
          <tbody class="divide-y">
            <tr :for={{dom_id, game} <- @streams.games} id={dom_id} class="text-center">
              <td>
                <.link
                  navigate={~p"/game/#{game.id}"}
                  class="text-green-500 font-semibold hover:underline"
                >
                  <%= game.id %>
                </.link>
              </td>
              <td><%= game.inserted_at %></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      send(self(), :load_games)
    end

    {:ok,
     assign(socket, page_title: "Games")
     |> stream(:games, [])}
  end

  @impl true
  def handle_info(:load_games, socket) do
    games = Golf.GamesDb.get_user_games(socket.assigns.current_user.id)
    {:noreply, stream(socket, :games, games, at: 0)}
  end
end
