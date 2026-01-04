defmodule Strong4life.WorkoutsTest do
  use Strong4life.DataCase

  alias Strong4life.Workouts

  alias Strong4life.Workouts.{
    Exercise,
    WorkoutTemplate,
    WorkoutTemplateExercise,
    WorkoutSession,
    WorkoutSet
  }

  import Strong4life.AccountsFixtures

  describe "get_suggested_weight/2" do
    setup do
      user = user_fixture()

      # Create test exercise with unique name
      exercise_name = "Test Exercise #{:rand.uniform(1_000_000)}"

      {:ok, exercise} =
        %Exercise{}
        |> Exercise.changeset(%{
          name: exercise_name,
          category: "compound",
          is_accessory: false,
          instructions: "Test instructions"
        })
        |> Repo.insert()

      # Create workout template with unique name
      template_name = "Test Template #{:rand.uniform(1_000_000)}"

      {:ok, template} =
        %WorkoutTemplate{}
        |> WorkoutTemplate.changeset(%{name: template_name})
        |> Repo.insert()

      # Link exercise to template
      {:ok, _wte} =
        %WorkoutTemplateExercise{}
        |> WorkoutTemplateExercise.changeset(%{
          workout_template_id: template.id,
          exercise_id: exercise.id,
          order: 1,
          target_sets: 3,
          target_reps: 5
        })
        |> Repo.insert()

      %{user: user, exercise: exercise, template: template}
    end

    test "returns nil when no workout history exists", %{user: user, exercise: exercise} do
      assert Workouts.get_suggested_weight(user.id, exercise.id) == nil
    end

    test "returns progressive overload when all reps completed", %{
      user: user,
      exercise: exercise,
      template: template
    } do
      # Create completed workout session
      {:ok, session} =
        %WorkoutSession{}
        |> WorkoutSession.changeset(%{
          user_id: user.id,
          workout_template_id: template.id,
          started_at: DateTime.utc_now(),
          completed_at: DateTime.utc_now()
        })
        |> Repo.insert()

      # Log 3 sets, all with 5 reps (target reps) at 135 lbs
      for set_num <- 1..3 do
        {:ok, _set} =
          %WorkoutSet{}
          |> WorkoutSet.changeset(%{
            workout_session_id: session.id,
            exercise_id: exercise.id,
            set_number: set_num,
            weight: Decimal.new("135"),
            reps: 5,
            rpe: 8
          })
          |> Repo.insert()
      end

      suggestion = Workouts.get_suggested_weight(user.id, exercise.id)

      assert Decimal.eq?(suggestion.last_weight, Decimal.new("135"))
      # Should suggest +5 lbs for compound lift
      assert Decimal.eq?(suggestion.suggested_weight, Decimal.new("140"))
      assert suggestion.progression_available == true
      assert Decimal.eq?(suggestion.increment, Decimal.new("5"))
    end

    test "suggests same weight when not all reps completed", %{
      user: user,
      exercise: exercise,
      template: template
    } do
      # Create completed workout session
      {:ok, session} =
        %WorkoutSession{}
        |> WorkoutSession.changeset(%{
          user_id: user.id,
          workout_template_id: template.id,
          started_at: DateTime.utc_now(),
          completed_at: DateTime.utc_now()
        })
        |> Repo.insert()

      # Log 3 sets, but last set only got 4 reps (target is 5)
      {:ok, _set1} =
        %WorkoutSet{}
        |> WorkoutSet.changeset(%{
          workout_session_id: session.id,
          exercise_id: exercise.id,
          set_number: 1,
          weight: Decimal.new("135"),
          reps: 5,
          rpe: 8
        })
        |> Repo.insert()

      {:ok, _set2} =
        %WorkoutSet{}
        |> WorkoutSet.changeset(%{
          workout_session_id: session.id,
          exercise_id: exercise.id,
          set_number: 2,
          weight: Decimal.new("135"),
          reps: 5,
          rpe: 9
        })
        |> Repo.insert()

      {:ok, _set3} =
        %WorkoutSet{}
        |> WorkoutSet.changeset(%{
          workout_session_id: session.id,
          exercise_id: exercise.id,
          set_number: 3,
          weight: Decimal.new("135"),
          reps: 4,
          # Failed to complete all reps
          rpe: 10
        })
        |> Repo.insert()

      suggestion = Workouts.get_suggested_weight(user.id, exercise.id)

      assert Decimal.eq?(suggestion.last_weight, Decimal.new("135"))
      # Should suggest same weight (no progression)
      assert Decimal.eq?(suggestion.suggested_weight, Decimal.new("135"))
      assert suggestion.progression_available == false
      assert Decimal.eq?(suggestion.increment, Decimal.new("5"))
    end

    test "suggests smaller increment for accessory exercises", %{user: user, template: template} do
      # Create accessory exercise with unique name
      accessory_name = "Test Accessory #{:rand.uniform(1_000_000)}"

      {:ok, accessory} =
        %Exercise{}
        |> Exercise.changeset(%{
          name: accessory_name,
          category: "accessory",
          is_accessory: true,
          instructions: "Test instructions"
        })
        |> Repo.insert()

      # Link to template
      {:ok, _wte} =
        %WorkoutTemplateExercise{}
        |> WorkoutTemplateExercise.changeset(%{
          workout_template_id: template.id,
          exercise_id: accessory.id,
          order: 2,
          target_sets: 3,
          target_reps: 12
        })
        |> Repo.insert()

      # Create completed workout session
      {:ok, session} =
        %WorkoutSession{}
        |> WorkoutSession.changeset(%{
          user_id: user.id,
          workout_template_id: template.id,
          started_at: DateTime.utc_now(),
          completed_at: DateTime.utc_now()
        })
        |> Repo.insert()

      # Log 3 sets, all with 12 reps at 30 lbs
      for set_num <- 1..3 do
        {:ok, _set} =
          %WorkoutSet{}
          |> WorkoutSet.changeset(%{
            workout_session_id: session.id,
            exercise_id: accessory.id,
            set_number: set_num,
            weight: Decimal.new("30"),
            reps: 12,
            rpe: 7
          })
          |> Repo.insert()
      end

      suggestion = Workouts.get_suggested_weight(user.id, accessory.id)

      assert Decimal.eq?(suggestion.last_weight, Decimal.new("30"))
      # Should suggest +2.5 lbs for accessory lift
      assert Decimal.eq?(suggestion.suggested_weight, Decimal.new("32.5"))
      assert suggestion.progression_available == true
      assert Decimal.eq?(suggestion.increment, Decimal.new("2.5"))
    end

    test "uses most recent completed workout only", %{
      user: user,
      exercise: exercise,
      template: template
    } do
      # Create older completed workout (145 lbs)
      {:ok, old_session} =
        %WorkoutSession{}
        |> WorkoutSession.changeset(%{
          user_id: user.id,
          workout_template_id: template.id,
          started_at: DateTime.add(DateTime.utc_now(), -7, :day),
          completed_at: DateTime.add(DateTime.utc_now(), -7, :day)
        })
        |> Repo.insert()

      {:ok, _old_set} =
        %WorkoutSet{}
        |> WorkoutSet.changeset(%{
          workout_session_id: old_session.id,
          exercise_id: exercise.id,
          set_number: 1,
          weight: Decimal.new("145"),
          reps: 5
        })
        |> Repo.insert()

      # Create newer completed workout (150 lbs, all reps completed)
      {:ok, new_session} =
        %WorkoutSession{}
        |> WorkoutSession.changeset(%{
          user_id: user.id,
          workout_template_id: template.id,
          started_at: DateTime.add(DateTime.utc_now(), -1, :day),
          completed_at: DateTime.add(DateTime.utc_now(), -1, :day)
        })
        |> Repo.insert()

      for set_num <- 1..3 do
        {:ok, _set} =
          %WorkoutSet{}
          |> WorkoutSet.changeset(%{
            workout_session_id: new_session.id,
            exercise_id: exercise.id,
            set_number: set_num,
            weight: Decimal.new("150"),
            reps: 5
          })
          |> Repo.insert()
      end

      suggestion = Workouts.get_suggested_weight(user.id, exercise.id)

      # Should use most recent workout (150 lbs), not older one
      assert Decimal.eq?(suggestion.last_weight, Decimal.new("150"))
      assert Decimal.eq?(suggestion.suggested_weight, Decimal.new("155"))
      assert suggestion.progression_available == true
    end

    test "ignores incomplete workout sessions", %{
      user: user,
      exercise: exercise,
      template: template
    } do
      # Create incomplete workout session (no completed_at)
      {:ok, incomplete_session} =
        %WorkoutSession{}
        |> WorkoutSession.changeset(%{
          user_id: user.id,
          workout_template_id: template.id,
          started_at: DateTime.utc_now()
          # No completed_at
        })
        |> Repo.insert()

      {:ok, _set} =
        %WorkoutSet{}
        |> WorkoutSet.changeset(%{
          workout_session_id: incomplete_session.id,
          exercise_id: exercise.id,
          set_number: 1,
          weight: Decimal.new("200"),
          reps: 5
        })
        |> Repo.insert()

      # Should return nil because no completed sessions exist
      assert Workouts.get_suggested_weight(user.id, exercise.id) == nil
    end
  end
end
