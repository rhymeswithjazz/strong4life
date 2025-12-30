defmodule Strong4lifeWeb.ProgressLive do
  use Strong4lifeWeb, :live_view

  alias Strong4life.Workouts

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    exercises = Workouts.list_exercises()
    selected_exercise = List.first(exercises)

    {weight_history, volume_history} =
      if selected_exercise do
        {
          Workouts.get_exercise_weight_history(user.id, selected_exercise.id),
          Workouts.get_exercise_volume_history(user.id, selected_exercise.id)
        }
      else
        {[], []}
      end

    {:ok,
     assign(socket,
       page_title: "Progress",
       exercises: exercises,
       selected_exercise: selected_exercise,
       weight_history: weight_history,
       volume_history: volume_history,
       chart_type: "weight"
     )}
  end

  @impl true
  def handle_event("select_exercise", %{"exercise_id" => exercise_id}, socket) do
    user = socket.assigns.current_scope.user
    selected_exercise = Enum.find(socket.assigns.exercises, &(&1.id == exercise_id))

    {weight_history, volume_history} =
      if selected_exercise do
        {
          Workouts.get_exercise_weight_history(user.id, selected_exercise.id),
          Workouts.get_exercise_volume_history(user.id, selected_exercise.id)
        }
      else
        {[], []}
      end

    {:noreply,
     assign(socket,
       selected_exercise: selected_exercise,
       weight_history: weight_history,
       volume_history: volume_history
     )}
  end

  @impl true
  def handle_event("toggle_chart", %{"type" => type}, socket) do
    {:noreply, assign(socket, chart_type: type)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
      <div class="max-w-lg mx-auto px-4 py-6">
        <!-- Header -->
        <header class="flex items-center justify-between mb-6">
          <.link navigate={~p"/dashboard"} class="text-slate-400 hover:text-white">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
          </.link>
          <h1 class="text-xl font-bold text-white">Progress</h1>
          <div class="w-6"></div>
        </header>

        <!-- Exercise Selector -->
        <div class="mb-6">
          <label class="block text-slate-400 text-sm mb-2">Select Exercise</label>
          <select
            phx-change="select_exercise"
            name="exercise_id"
            class="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:ring-2 focus:ring-emerald-500"
          >
            <%= for exercise <- @exercises do %>
              <option value={exercise.id} selected={@selected_exercise && @selected_exercise.id == exercise.id}>
                {exercise.name}
              </option>
            <% end %>
          </select>
        </div>

        <!-- Chart Type Toggle -->
        <div class="flex gap-2 mb-6">
          <button
            phx-click="toggle_chart"
            phx-value-type="weight"
            class={[
              "flex-1 py-2 px-4 rounded-xl font-medium transition-colors",
              if(@chart_type == "weight",
                do: "bg-emerald-500 text-slate-900",
                else: "bg-slate-700/50 text-slate-300 hover:bg-slate-700"
              )
            ]}
          >
            Weight
          </button>
          <button
            phx-click="toggle_chart"
            phx-value-type="volume"
            class={[
              "flex-1 py-2 px-4 rounded-xl font-medium transition-colors",
              if(@chart_type == "volume",
                do: "bg-emerald-500 text-slate-900",
                else: "bg-slate-700/50 text-slate-300 hover:bg-slate-700"
              )
            ]}
          >
            Volume
          </button>
        </div>

        <!-- Chart -->
        <div class="bg-slate-800/50 backdrop-blur rounded-2xl border border-slate-700 p-4 mb-6">
          <%= if @chart_type == "weight" do %>
            <h3 class="text-white font-medium mb-4">Weight Progress (lbs)</h3>
            <%= if @weight_history == [] do %>
              <div class="text-center py-8 text-slate-500">
                No data yet. Start logging workouts to see your progress!
              </div>
            <% else %>
              <div
                id="weight-chart"
                phx-hook="Chart"
                data-chart-type="line"
                data-chart-data={Jason.encode!(chart_data(@weight_history, "weight"))}
                class="h-64"
              >
                <!-- Fallback simple visualization -->
                <.simple_chart data={@weight_history} field={:max_weight} />
              </div>
            <% end %>
          <% else %>
            <h3 class="text-white font-medium mb-4">Volume Progress (lbs × reps)</h3>
            <%= if @volume_history == [] do %>
              <div class="text-center py-8 text-slate-500">
                No data yet. Start logging workouts to see your progress!
              </div>
            <% else %>
              <div
                id="volume-chart"
                phx-hook="Chart"
                data-chart-type="line"
                data-chart-data={Jason.encode!(chart_data(@volume_history, "volume"))}
                class="h-64"
              >
                <!-- Fallback simple visualization -->
                <.simple_chart data={@volume_history} field={:volume} />
              </div>
            <% end %>
          <% end %>
        </div>

        <!-- Stats Summary -->
        <%= if @selected_exercise do %>
          <div class="grid grid-cols-2 gap-4 mb-6">
            <div class="bg-slate-800/50 backdrop-blur rounded-2xl border border-slate-700 p-4">
              <div class="text-slate-400 text-sm mb-1">Best Weight</div>
              <div class="text-2xl font-bold text-white">
                {get_max_weight(@weight_history)} <span class="text-sm text-slate-500">lbs</span>
              </div>
            </div>
            <div class="bg-slate-800/50 backdrop-blur rounded-2xl border border-slate-700 p-4">
              <div class="text-slate-400 text-sm mb-1">Sessions</div>
              <div class="text-2xl font-bold text-white">
                {length(@weight_history)}
              </div>
            </div>
          </div>
        <% end %>

        <!-- Navigation -->
        <nav class="fixed bottom-0 left-0 right-0 bg-slate-900/95 backdrop-blur border-t border-slate-800 px-4 py-3">
          <div class="max-w-lg mx-auto flex justify-around">
            <.link navigate={~p"/dashboard"} class="flex flex-col items-center text-slate-400 hover:text-slate-300">
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
            <.link navigate={~p"/progress"} class="flex flex-col items-center text-emerald-400">
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

  attr :data, :list, required: true
  attr :field, :atom, required: true

  defp simple_chart(assigns) do
    max_value =
      assigns.data
      |> Enum.map(&Map.get(&1, assigns.field))
      |> Enum.filter(&(&1 != nil))
      |> Enum.max(fn -> 1 end)
      |> Decimal.to_float()

    assigns = assign(assigns, :max_value, max_value)

    ~H"""
    <div class="flex items-end justify-between h-48 gap-1">
      <%= for item <- @data do %>
        <% value = Map.get(item, @field) %>
        <% height = if value && @max_value > 0, do: Decimal.to_float(value) / @max_value * 100, else: 0 %>
        <div class="flex-1 flex flex-col items-center">
          <div
            class="w-full bg-emerald-500 rounded-t transition-all"
            style={"height: #{height}%"}
          ></div>
          <div class="text-xs text-slate-500 mt-1 truncate w-full text-center">
            {format_chart_date(item.date)}
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp chart_data(data, type) do
    labels = Enum.map(data, &format_chart_date(&1.date))

    values =
      case type do
        "weight" -> Enum.map(data, &Decimal.to_float(&1.max_weight || Decimal.new(0)))
        "volume" -> Enum.map(data, &Decimal.to_float(&1.volume || Decimal.new(0)))
      end

    %{
      labels: labels,
      datasets: [
        %{
          data: values,
          borderColor: "#10b981",
          backgroundColor: "rgba(16, 185, 129, 0.1)",
          fill: true,
          tension: 0.3
        }
      ]
    }
  end

  defp format_chart_date(date) when is_binary(date) do
    # Handle string dates from the database
    date
  end

  defp format_chart_date(%Date{} = date) do
    Calendar.strftime(date, "%m/%d")
  end

  defp get_max_weight([]), do: "-"

  defp get_max_weight(history) do
    history
    |> Enum.map(& &1.max_weight)
    |> Enum.filter(&(&1 != nil))
    |> Enum.max(fn -> Decimal.new(0) end)
    |> Decimal.to_string()
  end
end

