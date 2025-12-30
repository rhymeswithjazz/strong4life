defmodule Strong4lifeWeb.DashboardLive do
  use Strong4lifeWeb, :live_view

  alias Strong4life.Workouts

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    # Get workout stats
    total_workouts = Workouts.count_completed_sessions(user.id)
    streak = Workouts.calculate_streak(user.id)
    next_workout_type = Workouts.get_next_workout_type(user.id)

    # Get the next workout template
    next_template = Workouts.get_workout_template_by_name(next_workout_type)

    # Check if there's an in-progress workout
    in_progress = Workouts.get_in_progress_session(user.id)

    # Get last completed workout
    last_session =
      case Workouts.list_user_sessions(user.id, limit: 1) do
        [session] -> session
        _ -> nil
      end

    {:ok,
     assign(socket,
       page_title: "Dashboard",
       total_workouts: total_workouts,
       streak: streak,
       next_workout_type: next_workout_type,
       next_template: next_template,
       in_progress: in_progress,
       last_session: last_session
     )}
  end

  @impl true
  def handle_event("start_workout", _params, socket) do
    user = socket.assigns.current_scope.user
    template = socket.assigns.next_template

    case Workouts.start_session(user.id, template.id) do
      {:ok, session} ->
        {:noreply, push_navigate(socket, to: ~p"/workout/#{session.id}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to start workout")}
    end
  end

  @impl true
  def handle_event("continue_workout", _params, socket) do
    in_progress = socket.assigns.in_progress
    {:noreply, push_navigate(socket, to: ~p"/workout/#{in_progress.id}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
      <div class="max-w-lg mx-auto px-4 py-8">
        <!-- Header -->
        <header class="text-center mb-8">
          <h1 class="text-3xl font-bold text-white mb-2">Strong4Life</h1>
          <p class="text-slate-400">Your strength training companion</p>
        </header>

        <!-- Stats Cards -->
        <div class="grid grid-cols-2 gap-4 mb-8">
          <div class="bg-slate-800/50 backdrop-blur rounded-2xl p-4 border border-slate-700">
            <div class="text-4xl font-bold text-emerald-400">{@total_workouts}</div>
            <div class="text-slate-400 text-sm">Total Workouts</div>
          </div>
          <div class="bg-slate-800/50 backdrop-blur rounded-2xl p-4 border border-slate-700">
            <div class="text-4xl font-bold text-amber-400">{@streak}</div>
            <div class="text-slate-400 text-sm">Week Streak</div>
          </div>
        </div>

        <!-- In-Progress Workout Banner -->
        <%= if @in_progress do %>
          <div class="bg-amber-500/20 border border-amber-500/50 rounded-2xl p-4 mb-6">
            <div class="flex items-center justify-between">
              <div>
                <div class="text-amber-400 font-semibold">Workout In Progress</div>
                <div class="text-slate-400 text-sm">
                  Started {format_time_ago(@in_progress.started_at)}
                </div>
              </div>
              <button
                phx-click="continue_workout"
                class="bg-amber-500 hover:bg-amber-400 text-slate-900 font-semibold px-4 py-2 rounded-xl transition-colors"
              >
                Continue
              </button>
            </div>
          </div>
        <% end %>

        <!-- Next Workout Card -->
        <div class="bg-slate-800/50 backdrop-blur rounded-2xl border border-slate-700 overflow-hidden mb-6">
          <div class="p-6">
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-xl font-bold text-white">Today's Workout</h2>
              <span class="bg-emerald-500/20 text-emerald-400 px-3 py-1 rounded-full text-sm font-medium">
                {@next_workout_type}
              </span>
            </div>

            <%= if @next_template do %>
              <p class="text-slate-400 text-sm mb-4">{@next_template.description}</p>

              <!-- Exercise List -->
              <div class="space-y-3 mb-6">
                <%= for wte <- Enum.sort_by(@next_template.workout_template_exercises, & &1.order) do %>
                  <div class="flex items-center justify-between bg-slate-700/30 rounded-xl p-3">
                    <div>
                      <div class="text-white font-medium">{wte.exercise.name}</div>
                      <div class="text-slate-500 text-sm">
                        {wte.target_sets} × {wte.target_reps} reps
                      </div>
                    </div>
                    <%= if wte.exercise.is_accessory do %>
                      <span class="text-xs text-slate-500 bg-slate-700 px-2 py-1 rounded">
                        Accessory
                      </span>
                    <% end %>
                  </div>
                <% end %>
              </div>

              <!-- Start Button -->
              <%= unless @in_progress do %>
                <button
                  phx-click="start_workout"
                  class="w-full bg-emerald-500 hover:bg-emerald-400 text-slate-900 font-bold py-4 rounded-xl transition-all transform hover:scale-[1.02] active:scale-[0.98]"
                >
                  Start Workout
                </button>
              <% end %>
            <% else %>
              <p class="text-slate-400">No workout template found. Please seed the database.</p>
            <% end %>
          </div>
        </div>

        <!-- Last Workout Summary -->
        <%= if @last_session do %>
          <div class="bg-slate-800/50 backdrop-blur rounded-2xl border border-slate-700 p-6">
            <h3 class="text-lg font-semibold text-white mb-3">Last Workout</h3>
            <div class="flex items-center justify-between text-slate-400 text-sm">
              <span>
                {if @last_session.workout_template, do: @last_session.workout_template.name, else: "Workout"}
              </span>
              <span>{format_date(@last_session.completed_at || @last_session.started_at)}</span>
            </div>
            <%= if @last_session.completed_at do %>
              <div class="mt-2 text-xs text-emerald-400">
                ✓ Completed
              </div>
            <% else %>
              <div class="mt-2 text-xs text-amber-400">
                ⏳ Not completed
              </div>
            <% end %>
          </div>
        <% end %>

        <!-- Navigation -->
        <nav class="fixed bottom-0 left-0 right-0 bg-slate-900/95 backdrop-blur border-t border-slate-800 px-4 py-3">
          <div class="max-w-lg mx-auto flex justify-around">
            <.link navigate={~p"/dashboard"} class="flex flex-col items-center text-emerald-400">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
              </svg>
              <span class="text-xs mt-1">Home</span>
            </.link>
            <.link navigate={~p"/history"} class="flex flex-col items-center text-slate-400 hover:text-slate-300">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span class="text-xs mt-1">History</span>
            </.link>
            <.link navigate={~p"/progress"} class="flex flex-col items-center text-slate-400 hover:text-slate-300">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
              </svg>
              <span class="text-xs mt-1">Progress</span>
            </.link>
            <.link navigate={~p"/users/settings"} class="flex flex-col items-center text-slate-400 hover:text-slate-300">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
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

  # Helper functions
  defp format_time_ago(datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime, :minute)

    cond do
      diff < 1 -> "just now"
      diff < 60 -> "#{diff} min ago"
      diff < 1440 -> "#{div(diff, 60)} hours ago"
      true -> "#{div(diff, 1440)} days ago"
    end
  end

  defp format_date(nil), do: ""

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%b %d, %Y")
  end
end

