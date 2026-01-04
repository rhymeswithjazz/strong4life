defmodule Strong4lifeWeb.SettingsLive do
  use Strong4lifeWeb, :live_view

  alias Strong4life.Accounts

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    {:ok,
     assign(socket,
       page_title: "Settings",
       user: user,
       changeset: Accounts.change_user_weight_unit(user)
     )}
  end

  @impl true
  def handle_event("update_weight_unit", %{"user" => user_params}, socket) do
    case Accounts.update_user_weight_unit(socket.assigns.user, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Weight unit updated successfully")
         |> assign(user: user, changeset: Accounts.change_user_weight_unit(user))}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
      <div class="max-w-lg mx-auto px-4 py-6">
        <header class="flex items-center justify-between mb-6">
          <.link navigate={~p"/dashboard"} class="text-slate-400 hover:text-white">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M15 19l-7-7 7-7"
              />
            </svg>
          </.link>
          <h1 class="text-xl font-bold text-white">Settings</h1>
          <div class="w-6"></div>
        </header>

        <div class="bg-slate-800/50 backdrop-blur rounded-2xl border border-slate-700 p-6">
          <h2 class="text-lg font-bold text-white mb-4">Preferences</h2>

          <.form
            for={@changeset}
            phx-submit="update_weight_unit"
            class="space-y-4"
          >
            <div>
              <label class="block text-slate-400 text-sm mb-3">Weight Units</label>
              <div class="flex gap-3">
                <label class="flex-1">
                  <input
                    type="radio"
                    name="user[weight_unit]"
                    value="lbs"
                    checked={@user.weight_unit == "lbs"}
                    class="sr-only peer"
                  />
                  <div class="px-4 py-3 rounded-xl text-center font-medium transition-colors cursor-pointer bg-slate-700 text-white peer-checked:bg-emerald-500 peer-checked:text-slate-900 hover:bg-slate-600 peer-checked:hover:bg-emerald-400">
                    lbs
                  </div>
                </label>

                <label class="flex-1">
                  <input
                    type="radio"
                    name="user[weight_unit]"
                    value="kg"
                    checked={@user.weight_unit == "kg"}
                    class="sr-only peer"
                  />
                  <div class="px-4 py-3 rounded-xl text-center font-medium transition-colors cursor-pointer bg-slate-700 text-white peer-checked:bg-emerald-500 peer-checked:text-slate-900 hover:bg-slate-600 peer-checked:hover:bg-emerald-400">
                    kg
                  </div>
                </label>
              </div>
            </div>

            <button
              type="submit"
              class="w-full bg-emerald-500 hover:bg-emerald-400 text-slate-900 font-bold py-3 rounded-xl transition-colors"
            >
              Save Settings
            </button>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
