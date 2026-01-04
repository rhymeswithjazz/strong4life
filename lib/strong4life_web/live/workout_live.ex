defmodule Strong4lifeWeb.WorkoutLive do
  use Strong4lifeWeb, :live_view

  alias Strong4life.Repo
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
         rest_initial_duration: 0,
         custom_rest_duration: nil,
         show_complete_modal: false,
         delete_set_id: nil
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
                id: existing.id,
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
    set_number_int = String.to_integer(set_number)

    # Check if set already exists to determine flash message
    existing_set =
      Repo.get_by(Workouts.WorkoutSet,
        workout_session_id: session.id,
        exercise_id: exercise_id,
        set_number: set_number_int
      )

    is_update = existing_set != nil

    attrs = %{
      workout_session_id: session.id,
      exercise_id: exercise_id,
      set_number: set_number_int,
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

        flash_message = if is_update, do: "Set updated!", else: "Set logged!"

        # Start rest timer
        {:noreply,
         socket
         |> put_flash(:info, flash_message)
         |> assign(session: updated_session, exercises: exercises)
         |> start_rest_timer()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to log set")}
    end
  end

  @impl true
  def handle_event("skip_rest", _params, socket) do
    socket = assign(socket, rest_timer: nil, rest_seconds: 0)
    {:noreply, maybe_advance_to_next_exercise(socket)}
  end

  @impl true
  def handle_event("add_rest_time", %{"seconds" => seconds}, socket) do
    new_seconds = socket.assigns.rest_seconds + String.to_integer(seconds)
    {:noreply, assign(socket, rest_seconds: new_seconds)}
  end

  @impl true
  def handle_event("reset_rest_timer", _params, socket) do
    {:noreply, assign(socket, rest_seconds: socket.assigns.rest_initial_duration)}
  end

  @impl true
  def handle_event("set_rest_duration", %{"duration" => duration}, socket) do
    duration_int = String.to_integer(duration)
    {:noreply, assign(socket, custom_rest_duration: duration_int)}
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
  def handle_event("show_delete_modal", %{"set_id" => set_id}, socket) do
    {:noreply, assign(socket, delete_set_id: set_id)}
  end

  @impl true
  def handle_event("hide_delete_modal", _params, socket) do
    {:noreply, assign(socket, delete_set_id: nil)}
  end

  @impl true
  def handle_event("delete_set", _params, socket) do
    set_id = socket.assigns.delete_set_id

    if set_id do
      set = Repo.get!(Workouts.WorkoutSet, set_id)

      case Workouts.delete_set(set) do
        {:ok, _deleted_set} ->
          # Reload session to get updated sets
          updated_session = Workouts.get_session!(socket.assigns.session.id)
          user = socket.assigns.current_scope.user

          exercises =
            get_exercises_with_progress(socket.assigns.template, updated_session, user.id)

          {:noreply,
           socket
           |> put_flash(:info, "Set deleted")
           |> assign(session: updated_session, exercises: exercises, delete_set_id: nil)}

        {:error, _changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, "Failed to delete set")
           |> assign(delete_set_id: nil)}
      end
    else
      {:noreply, socket}
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
        # Rest complete - trigger audio and vibration notification, then maybe advance
        {:noreply,
         socket
         |> assign(rest_timer: nil, rest_seconds: 0)
         |> push_event("rest_timer_complete", %{})
         |> maybe_advance_to_next_exercise()}
      else
        {:noreply, assign(socket, rest_seconds: new_seconds)}
      end
    else
      {:noreply, socket}
    end
  end

  defp start_rest_timer(socket) do
    # Use custom duration if set, otherwise default: 2 minutes for compound, 90 seconds for accessory
    current_exercise = Enum.at(socket.assigns.exercises, socket.assigns.current_exercise_index)
    default_rest_time = if current_exercise.exercise.is_accessory, do: 90, else: 120
    rest_time = socket.assigns.custom_rest_duration || default_rest_time

    assign(socket,
      rest_timer: true,
      rest_seconds: rest_time,
      rest_initial_duration: rest_time
    )
  end

  defp maybe_advance_to_next_exercise(socket) do
    current_index = socket.assigns.current_exercise_index
    current_exercise = Enum.at(socket.assigns.exercises, current_index)

    # Check if all sets for current exercise are completed
    all_sets_complete? =
      current_exercise.sets
      |> Enum.all?(fn set -> set.completed end)

    # If all sets complete and there's a next exercise, advance
    next_index = current_index + 1
    has_next_exercise? = next_index < length(socket.assigns.exercises)

    if all_sets_complete? && has_next_exercise? do
      assign(socket, current_exercise_index: next_index)
    else
      socket
    end
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
      <div id="workout-container" phx-hook="RestTimer" class="max-w-lg mx-auto px-4 py-6">
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
          <div
            id="rest-timer-overlay"
            class="fixed inset-0 bg-slate-900/95 backdrop-blur flex items-center justify-center z-50"
          >
            <div class="text-center max-w-md mx-auto px-6">
              <div class="text-slate-400 text-lg mb-2">Rest Timer</div>
              <div class="text-7xl font-bold text-white mb-6">
                {format_time(@rest_seconds)}
              </div>
              
    <!-- Duration Picker -->
              <div class="mb-6">
                <label class="block text-slate-400 text-sm mb-3">Default Rest Duration</label>
                <div class="flex gap-2 justify-center">
                  <button
                    phx-click="set_rest_duration"
                    phx-value-duration="60"
                    class={"px-4 py-2 rounded-xl font-medium transition-colors #{if @custom_rest_duration == 60, do: "bg-emerald-500 text-slate-900", else: "bg-slate-700 hover:bg-slate-600 text-white"}"}
                  >
                    1:00
                  </button>
                  <button
                    phx-click="set_rest_duration"
                    phx-value-duration="90"
                    class={"px-4 py-2 rounded-xl font-medium transition-colors #{if @custom_rest_duration == 90, do: "bg-emerald-500 text-slate-900", else: "bg-slate-700 hover:bg-slate-600 text-white"}"}
                  >
                    1:30
                  </button>
                  <button
                    phx-click="set_rest_duration"
                    phx-value-duration="120"
                    class={"px-4 py-2 rounded-xl font-medium transition-colors #{if @custom_rest_duration == 120, do: "bg-emerald-500 text-slate-900", else: "bg-slate-700 hover:bg-slate-600 text-white"}"}
                  >
                    2:00
                  </button>
                  <button
                    phx-click="set_rest_duration"
                    phx-value-duration="180"
                    class={"px-4 py-2 rounded-xl font-medium transition-colors #{if @custom_rest_duration == 180, do: "bg-emerald-500 text-slate-900", else: "bg-slate-700 hover:bg-slate-600 text-white"}"}
                  >
                    3:00
                  </button>
                </div>
              </div>
              
    <!-- Quick Adjust -->
              <div class="flex gap-3 justify-center mb-6">
                <button
                  phx-click="add_rest_time"
                  phx-value-seconds="30"
                  class="bg-slate-700 hover:bg-slate-600 text-white px-4 py-2 rounded-xl font-medium"
                >
                  +30s
                </button>
                <button
                  phx-click="add_rest_time"
                  phx-value-seconds="60"
                  class="bg-slate-700 hover:bg-slate-600 text-white px-4 py-2 rounded-xl font-medium"
                >
                  +1min
                </button>
                <button
                  phx-click="reset_rest_timer"
                  class="bg-slate-700 hover:bg-slate-600 text-white px-4 py-2 rounded-xl font-medium"
                >
                  Reset
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
        
    <!-- Delete Set Modal -->
        <%= if @delete_set_id do %>
          <% set_to_delete = Enum.find(@session.workout_sets, &(&1.id == @delete_set_id)) %>
          <%= if set_to_delete do %>
            <% exercise =
              Enum.find(
                @template.workout_template_exercises,
                &(&1.exercise_id == set_to_delete.exercise_id)
              ).exercise %>
            <div class="fixed inset-0 bg-slate-900/95 backdrop-blur flex items-center justify-center z-50 p-4">
              <div class="bg-slate-800 rounded-2xl border border-red-900/50 p-6 w-full max-w-md">
                <h2 class="text-xl font-bold text-red-400 mb-4">Delete Set</h2>
                <div class="mb-6">
                  <p class="text-slate-300 mb-4">Are you sure you want to delete this set?</p>
                  <div class="bg-slate-700/50 rounded-lg p-4 border border-slate-600">
                    <p class="text-white font-medium mb-2">
                      {exercise.name} - Set {set_to_delete.set_number}
                    </p>
                    <div class="text-slate-400 text-sm space-y-1">
                      <p>Weight: {set_to_delete.weight} lbs</p>
                      <p>Reps: {set_to_delete.reps}</p>
                      <%= if set_to_delete.rpe do %>
                        <p>RPE: {set_to_delete.rpe}</p>
                      <% end %>
                    </div>
                  </div>
                  <p class="text-red-400 text-sm mt-4">This action cannot be undone.</p>
                </div>
                <div class="flex gap-3">
                  <button
                    type="button"
                    phx-click="hide_delete_modal"
                    class="flex-1 bg-slate-700 hover:bg-slate-600 text-white font-medium py-3 rounded-xl"
                  >
                    Cancel
                  </button>
                  <button
                    type="button"
                    phx-click="delete_set"
                    class="flex-1 bg-red-500 hover:bg-red-400 text-white font-bold py-3 rounded-xl"
                  >
                    Delete Set
                  </button>
                </div>
              </div>
            </div>
          <% end %>
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
          <div class="flex items-center gap-2">
            <span class="text-emerald-400 text-sm">✓ Logged</span>
            <button
              type="button"
              phx-click="show_delete_modal"
              phx-value-set_id={@set.id}
              class="text-red-400 hover:text-red-300 transition-colors"
              title="Delete set"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                />
              </svg>
            </button>
          </div>
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
