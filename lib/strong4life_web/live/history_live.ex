defmodule Strong4lifeWeb.HistoryLive do
  use Strong4lifeWeb, :live_view

  alias Strong4life.Workouts

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    sessions = Workouts.list_user_sessions(user.id, limit: 20)

    {:ok,
     assign(socket,
       page_title: "Workout History",
       sessions: sessions,
       selected_session: nil,
       weight_unit: user.weight_unit,
       editing_notes: false
     )}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    session = Workouts.get_session!(id)

    # Group sets by exercise
    exercises_with_sets =
      session.workout_sets
      |> Enum.group_by(& &1.exercise)
      |> Enum.map(fn {exercise, sets} ->
        {exercise, Enum.sort_by(sets, & &1.set_number)}
      end)
      |> Enum.sort_by(fn {_ex, sets} -> hd(sets).inserted_at end)

    {:noreply,
     assign(socket, selected_session: session, exercises_with_sets: exercises_with_sets)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply,
     assign(socket, selected_session: nil, exercises_with_sets: [], editing_notes: false)}
  end

  @impl true
  def handle_event("toggle_edit_notes", _params, socket) do
    {:noreply, assign(socket, editing_notes: !socket.assigns.editing_notes)}
  end

  @impl true
  def handle_event("save_notes", %{"notes" => notes}, socket) do
    case Workouts.update_session_notes(socket.assigns.selected_session, %{notes: notes}) do
      {:ok, updated_session} ->
        {:noreply,
         socket
         |> assign(selected_session: updated_session, editing_notes: false)
         |> put_flash(:info, "Workout notes saved")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to save notes")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
      <div class="max-w-lg mx-auto px-4 py-6">
        <!-- Header -->
        <header class="flex items-center justify-between mb-6">
          <%= if @selected_session do %>
            <.link patch={~p"/history"} class="text-slate-400 hover:text-white">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 19l-7-7 7-7"
                />
              </svg>
            </.link>
            <h1 class="text-xl font-bold text-white">
              {if @selected_session.workout_template,
                do: @selected_session.workout_template.name,
                else: "Workout"}
            </h1>
            <div class="w-6"></div>
          <% else %>
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
            <h1 class="text-xl font-bold text-white">Workout History</h1>
            <div class="w-6"></div>
          <% end %>
        </header>

        <%= if @selected_session do %>
          <!-- Session Detail View -->
          <div class="space-y-4">
            <!-- Session Info -->
            <div class="bg-slate-800/50 backdrop-blur rounded-2xl border border-slate-700 p-4">
              <div class="flex items-center justify-between">
                <div>
                  <div class="text-white font-medium">
                    {format_date(@selected_session.completed_at || @selected_session.started_at)}
                  </div>
                  <div class="text-slate-500 text-sm">
                    {format_time_of_day(@selected_session.started_at)}
                  </div>
                </div>
                <%= if @selected_session.completed_at do %>
                  <span class="bg-emerald-500/20 text-emerald-400 px-3 py-1 rounded-full text-sm">
                    Completed
                  </span>
                <% else %>
                  <span class="bg-amber-500/20 text-amber-400 px-3 py-1 rounded-full text-sm">
                    In Progress
                  </span>
                <% end %>
              </div>
              <div class="mt-3 pt-3 border-t border-slate-700">
                <div class="flex items-center justify-between mb-1">
                  <div class="text-slate-500 text-xs">Notes</div>
                  <button
                    phx-click="toggle_edit_notes"
                    class="text-emerald-400 hover:text-emerald-300 text-xs"
                  >
                    {if @editing_notes, do: "Cancel", else: "Edit"}
                  </button>
                </div>
                <%= if @editing_notes do %>
                  <form phx-submit="save_notes" class="mt-2">
                    <textarea
                      name="notes"
                      rows="3"
                      class="w-full bg-slate-700 border border-slate-600 rounded-lg px-3 py-2 text-white text-sm placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500 mb-2"
                      placeholder="Add notes about this workout..."
                    >{@selected_session.notes}</textarea>
                    <button
                      type="submit"
                      class="w-full bg-emerald-500 hover:bg-emerald-400 text-slate-900 font-medium py-2 rounded-lg text-sm"
                    >
                      Save Notes
                    </button>
                  </form>
                <% else %>
                  <div class="text-slate-300 text-sm">
                    {@selected_session.notes || "No notes yet"}
                  </div>
                <% end %>
              </div>
            </div>
            
    <!-- Exercises -->
            <%= for {exercise, sets} <- @exercises_with_sets do %>
              <div class="bg-slate-800/50 backdrop-blur rounded-2xl border border-slate-700 p-4">
                <h3 class="text-white font-medium mb-3">{exercise.name}</h3>
                <div class="space-y-2">
                  <%= for set <- sets do %>
                    <div class="flex items-center justify-between text-sm">
                      <span class="text-slate-500">Set {set.set_number}</span>
                      <div class="flex items-center gap-4">
                        <span class="text-white">
                          {set.weight || "-"} {@weight_unit} × {set.reps || "-"}
                        </span>
                        <%= if set.rpe do %>
                          <span class="text-slate-500">RPE {set.rpe}</span>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        <% else %>
          <!-- Session List View -->
          <%= if @sessions == [] do %>
            <div class="text-center py-12">
              <div class="text-slate-500 text-lg mb-4">No workouts yet</div>
              <.link navigate={~p"/dashboard"} class="text-emerald-400 hover:text-emerald-300">
                Start your first workout →
              </.link>
            </div>
          <% else %>
            <div class="space-y-3">
              <%= for session <- @sessions do %>
                <.link
                  patch={~p"/history/#{session.id}"}
                  class="block bg-slate-800/50 backdrop-blur rounded-2xl border border-slate-700 p-4 hover:border-slate-600 transition-colors"
                >
                  <div class="flex items-center justify-between">
                    <div>
                      <div class="text-white font-medium">
                        {if session.workout_template,
                          do: session.workout_template.name,
                          else: "Workout"}
                      </div>
                      <div class="text-slate-500 text-sm">
                        {format_date(session.completed_at || session.started_at)}
                      </div>
                    </div>
                    <div class="flex items-center gap-3">
                      <%= if session.completed_at do %>
                        <span class="text-emerald-400 text-sm">✓</span>
                      <% else %>
                        <span class="text-amber-400 text-sm">In progress</span>
                      <% end %>
                      <svg
                        class="w-5 h-5 text-slate-500"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M9 5l7 7-7 7"
                        />
                      </svg>
                    </div>
                  </div>
                  <%= if length(session.workout_sets) > 0 do %>
                    <div class="mt-2 text-slate-500 text-sm">
                      {length(session.workout_sets)} sets logged
                    </div>
                  <% end %>
                </.link>
              <% end %>
            </div>
          <% end %>
        <% end %>
        
    <!-- Navigation -->
        <nav class="fixed bottom-0 left-0 right-0 bg-slate-900/95 backdrop-blur border-t border-slate-800 px-4 py-3">
          <div class="max-w-lg mx-auto flex justify-around">
            <.link
              navigate={~p"/dashboard"}
              class="flex flex-col items-center text-slate-400 hover:text-slate-300"
            >
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
                />
              </svg>
              <span class="text-xs mt-1">Home</span>
            </.link>
            <.link navigate={~p"/history"} class="flex flex-col items-center text-emerald-400">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              <span class="text-xs mt-1">History</span>
            </.link>
            <.link
              navigate={~p"/progress"}
              class="flex flex-col items-center text-slate-400 hover:text-slate-300"
            >
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                />
              </svg>
              <span class="text-xs mt-1">Progress</span>
            </.link>
            <.link
              navigate={~p"/users/settings"}
              class="flex flex-col items-center text-slate-400 hover:text-slate-300"
            >
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
                />
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                />
              </svg>
              <span class="text-xs mt-1">Settings</span>
            </.link>
          </div>
        </nav>
        
    <!-- Bottom padding for fixed nav -->
        <div class="h-20"></div>
      </div>
    </div>
    """
  end

  defp format_date(nil), do: ""

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y")
  end

  defp format_time_of_day(datetime) do
    Calendar.strftime(datetime, "%I:%M %p")
  end
end
