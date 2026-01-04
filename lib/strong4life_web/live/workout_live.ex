defmodule Strong4lifeWeb.WorkoutLive do
  use Strong4lifeWeb, :live_view

  alias Strong4life.Workouts

  @impl true
  def mount(%{"id" => session_id}, _session, socket) do
    user = socket.assigns.current_scope.user

    session = Workouts.get_session!(session_id)

    # Verify this session belongs to the current user
    if session.user_id != user.id do
      {:ok, push_navigate(socket, to: ~p"/dashboard")}
    else
      template = session.workout_template
      exercises = get_exercises_with_progress(template, session, user.id)

      # Subscribe to timer updates if connected
      if connected?(socket) do
        :timer.send_interval(1000, self(), :tick)
      end

      {:ok,
       assign(socket,
         page_title: template.name,
         session: session,
         template: template,
         exercises: exercises,
         current_exercise_index: 0,
         rest_timer: nil,
         rest_seconds: 0,
         show_complete_modal: false
       )}
    end
  end

  defp get_exercises_with_progress(template, session, user_id) do
    template.workout_template_exercises
    |> Enum.sort_by(& &1.order)
    |> Enum.map(fn wte ->
      exercise = wte.exercise
      suggestion = Workouts.get_suggested_weight(user_id, exercise.id)

      # Extract suggested weight from map or use nil if no history
      suggested_weight =
        case suggestion do
          %{suggested_weight: weight} -> weight
          _ -> nil
        end

      # Get existing sets for this exercise in this session
      existing_sets =
        session.workout_sets
        |> Enum.filter(&(&1.exercise_id == exercise.id))
        |> Enum.map(&{&1.set_number, &1})
        |> Map.new()

      # Build sets with existing data or defaults
      sets =
        for set_num <- 1..wte.target_sets do
          case Map.get(existing_sets, set_num) do
            nil ->
              %{
                set_number: set_num,
                weight: suggested_weight,
                reps: wte.target_reps,
                rpe: nil,
                completed: false
              }

            existing ->
              %{
                set_number: set_num,
                weight: existing.weight,
                reps: existing.reps,
                rpe: existing.rpe,
                completed: true
              }
          end
        end

      %{
        wte: wte,
        exercise: exercise,
        suggestion: suggestion,
        suggested_weight: suggested_weight,
        sets: sets
      }
    end)
  end

  @impl true
  def handle_event("log_set", params, socket) do
    %{
      "exercise_id" => exercise_id,
      "set_number" => set_number,
      "weight" => weight,
      "reps" => reps,
      "rpe" => rpe
    } = params

    session = socket.assigns.session

    attrs = %{
      workout_session_id: session.id,
      exercise_id: exercise_id,
      set_number: String.to_integer(set_number),
      weight: parse_decimal(weight),
      reps: parse_integer(reps),
      rpe: parse_integer(rpe)
    }

    case Workouts.upsert_set(attrs) do
      {:ok, _set} ->
        # Reload session to get updated sets
        updated_session = Workouts.get_session!(session.id)
        user = socket.assigns.current_scope.user
        exercises = get_exercises_with_progress(socket.assigns.template, updated_session, user.id)

        # Start rest timer
        {:noreply,
         socket
         |> assign(session: updated_session, exercises: exercises)
         |> start_rest_timer()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to log set")}
    end
  end

  @impl true
  def handle_event("skip_rest", _params, socket) do
    {:noreply, assign(socket, rest_timer: nil, rest_seconds: 0)}
  end

  @impl true
  def handle_event("add_rest_time", %{"seconds" => seconds}, socket) do
    new_seconds = socket.assigns.rest_seconds + String.to_integer(seconds)
    {:noreply, assign(socket, rest_seconds: new_seconds)}
  end

  @impl true
  def handle_event("show_complete_modal", _params, socket) do
    {:noreply, assign(socket, show_complete_modal: true)}
  end

  @impl true
  def handle_event("hide_complete_modal", _params, socket) do
    {:noreply, assign(socket, show_complete_modal: false)}
  end

  @impl true
  def handle_event("complete_workout", %{"notes" => notes}, socket) do
    session = socket.assigns.session

    case Workouts.complete_session(session, %{notes: notes}) do
      {:ok, _session} ->
        {:noreply,
         socket
         |> put_flash(:info, "Workout completed! Great job! 💪")
         |> push_navigate(to: ~p"/dashboard")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to complete workout")}
    end
  end

  @impl true
  def handle_event("select_exercise", %{"index" => index}, socket) do
    {:noreply, assign(socket, current_exercise_index: String.to_integer(index))}
  end

  @impl true
  def handle_info(:tick, socket) do
    if socket.assigns.rest_timer && socket.assigns.rest_seconds > 0 do
      new_seconds = socket.assigns.rest_seconds - 1

      if new_seconds <= 0 do
        # Rest complete - could play a sound here via JS hook
        {:noreply, assign(socket, rest_timer: nil, rest_seconds: 0)}
      else
        {:noreply, assign(socket, rest_seconds: new_seconds)}
      end
    else
      {:noreply, socket}
    end
  end

  defp start_rest_timer(socket) do
    # Default 2 minutes for compound, 90 seconds for accessory
    current_exercise = Enum.at(socket.assigns.exercises, socket.assigns.current_exercise_index)
    rest_time = if current_exercise.exercise.is_accessory, do: 90, else: 120

    assign(socket, rest_timer: true, rest_seconds: rest_time)
  end

  defp parse_decimal(""), do: nil
  defp parse_decimal(nil), do: nil
  defp parse_decimal(value) when is_binary(value), do: Decimal.new(value)
  defp parse_decimal(value), do: value

  defp parse_integer(""), do: nil
  defp parse_integer(nil), do: nil
  defp parse_integer(value) when is_binary(value), do: String.to_integer(value)
  defp parse_integer(value), do: value

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
      <div class="max-w-lg mx-auto px-4 py-6">
        <!-- Header -->
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
          <h1 class="text-xl font-bold text-white">{@template.name}</h1>
          <button
            phx-click="show_complete_modal"
            class="text-emerald-400 hover:text-emerald-300 font-medium"
          >
            Finish
          </button>
        </header>
        
    <!-- Rest Timer Overlay -->
        <%= if @rest_timer do %>
          <div class="fixed inset-0 bg-slate-900/95 backdrop-blur flex items-center justify-center z-50">
            <div class="text-center">
              <div class="text-slate-400 text-lg mb-2">Rest Timer</div>
              <div class="text-7xl font-bold text-white mb-6">
                {format_time(@rest_seconds)}
              </div>
              <div class="flex gap-4 justify-center mb-6">
                <button
                  phx-click="add_rest_time"
                  phx-value-seconds="30"
                  class="bg-slate-700 hover:bg-slate-600 text-white px-4 py-2 rounded-xl"
                >
                  +30s
                </button>
                <button
                  phx-click="add_rest_time"
                  phx-value-seconds="60"
                  class="bg-slate-700 hover:bg-slate-600 text-white px-4 py-2 rounded-xl"
                >
                  +1min
                </button>
              </div>
              <button
                phx-click="skip_rest"
                class="bg-emerald-500 hover:bg-emerald-400 text-slate-900 font-bold px-8 py-3 rounded-xl"
              >
                Skip Rest
              </button>
            </div>
          </div>
        <% end %>
        
    <!-- Exercise Tabs -->
        <div class="flex overflow-x-auto gap-2 mb-6 pb-2 -mx-4 px-4">
          <%= for {exercise_data, index} <- Enum.with_index(@exercises) do %>
            <button
              phx-click="select_exercise"
              phx-value-index={index}
              class={[
                "flex-shrink-0 px-4 py-2 rounded-full text-sm font-medium transition-colors",
                if(index == @current_exercise_index,
                  do: "bg-emerald-500 text-slate-900",
                  else: "bg-slate-700/50 text-slate-300 hover:bg-slate-700"
                )
              ]}
            >
              {short_name(exercise_data.exercise.name)}
              <%= if all_sets_complete?(exercise_data.sets) do %>
                <span class="ml-1">✓</span>
              <% end %>
            </button>
          <% end %>
        </div>
        
    <!-- Current Exercise Card -->
        <%= if current_exercise = Enum.at(@exercises, @current_exercise_index) do %>
          <div class="bg-slate-800/50 backdrop-blur rounded-2xl border border-slate-700 p-6 mb-6">
            <h2 class="text-xl font-bold text-white mb-2">
              {current_exercise.exercise.name}
            </h2>
            <p class="text-slate-400 text-sm mb-4">
              {current_exercise.wte.target_sets} sets × {current_exercise.wte.target_reps} reps
            </p>
            <%= if current_exercise.suggestion do %>
              <div class="mb-4 space-y-2">
                <div class="flex items-center gap-2">
                  <span class="text-sm text-slate-500">
                    Last time: {current_exercise.suggestion.last_weight} lbs
                  </span>
                </div>
                <%= if current_exercise.suggestion.progression_available do %>
                  <div class="flex items-center gap-2 bg-emerald-500/10 border border-emerald-500/30 rounded-lg px-3 py-2">
                    <svg
                      class="w-4 h-4 text-emerald-400"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"
                      />
                    </svg>
                    <span class="text-sm font-medium text-emerald-400">
                      Try {current_exercise.suggestion.suggested_weight} lbs
                      <span class="text-emerald-500/70">
                        (+{current_exercise.suggestion.increment} lbs)
                      </span>
                    </span>
                  </div>
                <% else %>
                  <div class="flex items-center gap-2 text-sm text-amber-400">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                      />
                    </svg>
                    <span>
                      Focus on hitting all reps at {current_exercise.suggestion.last_weight} lbs
                    </span>
                  </div>
                <% end %>
              </div>
            <% end %>
            
    <!-- Instructions -->
            <%= if current_exercise.exercise.instructions do %>
              <details class="mb-4">
                <summary class="text-slate-400 text-sm cursor-pointer hover:text-slate-300">
                  Instructions
                </summary>
                <p class="text-slate-500 text-sm mt-2 pl-4 border-l-2 border-slate-700">
                  {current_exercise.exercise.instructions}
                </p>
              </details>
            <% end %>
            
    <!-- Sets -->
            <div class="space-y-4">
              <%= for set <- current_exercise.sets do %>
                <.set_row
                  set={set}
                  exercise={current_exercise.exercise}
                  session_id={@session.id}
                  suggestion={current_exercise.suggestion}
                  target_reps={current_exercise.wte.target_reps}
                />
              <% end %>
            </div>
          </div>
        <% end %>
        
    <!-- Complete Modal -->
        <%= if @show_complete_modal do %>
          <div class="fixed inset-0 bg-slate-900/95 backdrop-blur flex items-center justify-center z-50 p-4">
            <div class="bg-slate-800 rounded-2xl border border-slate-700 p-6 w-full max-w-md">
              <h2 class="text-xl font-bold text-white mb-4">Complete Workout</h2>
              <form phx-submit="complete_workout">
                <div class="mb-4">
                  <label class="block text-slate-400 text-sm mb-2">Notes (optional)</label>
                  <textarea
                    name="notes"
                    rows="3"
                    class="w-full bg-slate-700 border border-slate-600 rounded-xl px-4 py-3 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                    placeholder="How did it go? Any notes for next time?"
                  ></textarea>
                </div>
                <div class="flex gap-3">
                  <button
                    type="button"
                    phx-click="hide_complete_modal"
                    class="flex-1 bg-slate-700 hover:bg-slate-600 text-white font-medium py-3 rounded-xl"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    class="flex-1 bg-emerald-500 hover:bg-emerald-400 text-slate-900 font-bold py-3 rounded-xl"
                  >
                    Complete
                  </button>
                </div>
              </form>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr :set, :map, required: true
  attr :exercise, :map, required: true
  attr :session_id, :string, required: true
  attr :suggestion, :map
  attr :target_reps, :integer, required: true

  defp set_row(assigns) do
    # Extract suggested weight from suggestion map
    suggested_weight =
      case assigns.suggestion do
        %{suggested_weight: weight} -> weight
        _ -> nil
      end

    assigns = assign(assigns, :suggested_weight, suggested_weight)

    ~H"""
    <form
      phx-submit="log_set"
      class={[
        "rounded-xl p-4 border transition-colors",
        if(@set.completed,
          do: "bg-emerald-500/10 border-emerald-500/30",
          else: "bg-slate-700/30 border-slate-700"
        )
      ]}
    >
      <input type="hidden" name="exercise_id" value={@exercise.id} />
      <input type="hidden" name="set_number" value={@set.set_number} />

      <div class="flex items-center justify-between mb-3">
        <span class="text-slate-400 font-medium">Set {@set.set_number}</span>
        <%= if @set.completed do %>
          <span class="text-emerald-400 text-sm">✓ Logged</span>
        <% end %>
      </div>

      <div class="grid grid-cols-3 gap-3">
        <div>
          <label class="block text-slate-500 text-xs mb-1">Weight (lbs)</label>
          <input
            type="number"
            name="weight"
            value={@set.weight || @suggested_weight}
            step="2.5"
            min="0"
            class="w-full bg-slate-800 border border-slate-600 rounded-lg px-3 py-2 text-white text-center focus:outline-none focus:ring-2 focus:ring-emerald-500"
          />
        </div>
        <div>
          <label class="block text-slate-500 text-xs mb-1">Reps</label>
          <input
            type="number"
            name="reps"
            value={@set.reps || @target_reps}
            min="0"
            class="w-full bg-slate-800 border border-slate-600 rounded-lg px-3 py-2 text-white text-center focus:outline-none focus:ring-2 focus:ring-emerald-500"
          />
        </div>
        <div>
          <label class="block text-slate-500 text-xs mb-1">RPE</label>
          <input
            type="number"
            name="rpe"
            value={@set.rpe}
            min="1"
            max="10"
            placeholder="1-10"
            class="w-full bg-slate-800 border border-slate-600 rounded-lg px-3 py-2 text-white text-center focus:outline-none focus:ring-2 focus:ring-emerald-500"
          />
        </div>
      </div>

      <button
        type="submit"
        class={[
          "w-full mt-3 font-medium py-2 rounded-lg transition-colors",
          if(@set.completed,
            do: "bg-emerald-500/20 text-emerald-400 hover:bg-emerald-500/30",
            else: "bg-emerald-500 text-slate-900 hover:bg-emerald-400"
          )
        ]}
      >
        {if @set.completed, do: "Update Set", else: "Log Set"}
      </button>
    </form>
    """
  end

  defp format_time(seconds) do
    minutes = div(seconds, 60)
    secs = rem(seconds, 60)
    "#{minutes}:#{String.pad_leading(Integer.to_string(secs), 2, "0")}"
  end

  defp short_name(name) do
    name
    |> String.replace("Barbell ", "")
    |> String.replace(" Press", "")
    |> String.split()
    |> Enum.take(2)
    |> Enum.join(" ")
  end

  defp all_sets_complete?(sets) do
    Enum.all?(sets, & &1.completed)
  end
end
