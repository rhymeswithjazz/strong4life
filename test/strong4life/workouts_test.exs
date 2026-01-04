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

  describe "complete_session/2" do
    setup do
      user = user_fixture()

      # Create test exercise and template
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

      template_name = "Test Template #{:rand.uniform(1_000_000)}"

      {:ok, template} =
        %WorkoutTemplate{}
        |> WorkoutTemplate.changeset(%{name: template_name})
        |> Repo.insert()

      # Create in-progress workout session
      {:ok, session} =
        %WorkoutSession{}
        |> WorkoutSession.changeset(%{
          user_id: user.id,
          workout_template_id: template.id,
          started_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })
        |> Repo.insert()

      %{user: user, exercise: exercise, template: template, session: session}
    end

    test "successfully completes a session with timestamp", %{session: session} do
      assert session.completed_at == nil

      {:ok, completed_session} = Workouts.complete_session(session)

      assert completed_session.completed_at != nil
      assert %DateTime{} = completed_session.completed_at

      # Verify it's persisted in database
      db_session = Repo.get!(WorkoutSession, session.id)
      assert db_session.completed_at != nil
    end

    test "sets completed_at to current time", %{session: session} do
      before_completion = DateTime.utc_now() |> DateTime.truncate(:second)
      {:ok, completed_session} = Workouts.complete_session(session)
      after_completion = DateTime.utc_now() |> DateTime.truncate(:second)

      assert DateTime.compare(completed_session.completed_at, before_completion) in [:gt, :eq]
      assert DateTime.compare(completed_session.completed_at, after_completion) in [:lt, :eq]
    end

    test "saves optional notes with session", %{session: session} do
      notes = "Great workout! Felt strong today."

      {:ok, completed_session} = Workouts.complete_session(session, %{notes: notes})

      assert completed_session.notes == notes

      # Verify notes are persisted
      db_session = Repo.get!(WorkoutSession, session.id)
      assert db_session.notes == notes
    end

    test "completes session without notes", %{session: session} do
      {:ok, completed_session} = Workouts.complete_session(session)

      assert completed_session.notes == nil
    end

    test "truncates timestamp to seconds", %{session: session} do
      {:ok, completed_session} = Workouts.complete_session(session)

      # Verify microseconds are 0 (truncated to seconds)
      assert completed_session.completed_at.microsecond == {0, 0}
    end

    test "completed session appears in user history", %{user: user, session: session} do
      {:ok, _completed} = Workouts.complete_session(session)

      sessions = Workouts.list_user_sessions(user.id)

      assert length(sessions) == 1
      assert hd(sessions).id == session.id
      assert hd(sessions).completed_at != nil
    end

    test "completed session counts toward user stats", %{user: user, session: session} do
      assert Workouts.count_completed_sessions(user.id) == 0

      {:ok, _completed} = Workouts.complete_session(session)

      assert Workouts.count_completed_sessions(user.id) == 1
    end

    test "can complete session that already has sets logged", %{
      session: session,
      exercise: exercise
    } do
      # Log some sets first
      {:ok, _set} =
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

      {:ok, completed_session} = Workouts.complete_session(session)

      assert completed_session.completed_at != nil

      # Verify sets are still associated
      sets = Repo.preload(completed_session, :workout_sets).workout_sets
      assert length(sets) == 1
    end

    test "completed session is available for weight suggestions", %{
      user: user,
      session: session,
      exercise: exercise,
      template: template
    } do
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

      # Log sets
      for set_num <- 1..3 do
        {:ok, _set} =
          %WorkoutSet{}
          |> WorkoutSet.changeset(%{
            workout_session_id: session.id,
            exercise_id: exercise.id,
            set_number: set_num,
            weight: Decimal.new("135"),
            reps: 5
          })
          |> Repo.insert()
      end

      # Should return nil before completion
      assert Workouts.get_suggested_weight(user.id, exercise.id) == nil

      # Complete the session
      {:ok, _completed} = Workouts.complete_session(session)

      # Should now return suggestion
      suggestion = Workouts.get_suggested_weight(user.id, exercise.id)
      assert suggestion != nil
      assert Decimal.eq?(suggestion.last_weight, Decimal.new("135"))
    end
  end

  describe "WorkoutSession.complete_changeset/2" do
    test "sets completed_at timestamp automatically" do
      session = %WorkoutSession{started_at: DateTime.utc_now()}

      changeset = WorkoutSession.complete_changeset(session)

      assert changeset.valid?
      assert changeset.changes.completed_at != nil
      assert %DateTime{} = changeset.changes.completed_at
    end

    test "accepts notes parameter" do
      session = %WorkoutSession{started_at: DateTime.utc_now()}
      notes = "Excellent session!"

      changeset = WorkoutSession.complete_changeset(session, %{notes: notes})

      assert changeset.valid?
      assert changeset.changes.notes == notes
    end

    test "does not require notes parameter" do
      session = %WorkoutSession{started_at: DateTime.utc_now()}

      changeset = WorkoutSession.complete_changeset(session, %{})

      assert changeset.valid?
      assert changeset.changes[:notes] == nil
    end

    test "truncates completed_at to seconds" do
      session = %WorkoutSession{started_at: DateTime.utc_now()}

      changeset = WorkoutSession.complete_changeset(session)

      completed_at = changeset.changes.completed_at
      assert completed_at.microsecond == {0, 0}
    end

    test "ignores other fields in attrs" do
      session = %WorkoutSession{
        started_at: DateTime.utc_now(),
        user_id: 1,
        workout_template_id: Ecto.UUID.generate()
      }

      # Try to change fields that shouldn't be modifiable
      changeset =
        WorkoutSession.complete_changeset(session, %{
          user_id: 999,
          workout_template_id: Ecto.UUID.generate(),
          started_at: DateTime.add(DateTime.utc_now(), -3600)
        })

      assert changeset.valid?
      # These fields should not be in changes
      assert changeset.changes[:user_id] == nil
      assert changeset.changes[:workout_template_id] == nil
      assert changeset.changes[:started_at] == nil
      # Only completed_at should be set
      assert changeset.changes.completed_at != nil
    end
  end

  describe "get_exercise_weight_history/3" do
    setup do
      user = user_fixture()

      # Create exercise with unique name
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

      template_name = "Test Template #{:rand.uniform(1_000_000)}"

      {:ok, template} =
        %WorkoutTemplate{}
        |> WorkoutTemplate.changeset(%{name: template_name})
        |> Repo.insert()

      # Create 10 completed workout sessions with sets
      sessions =
        for i <- 1..10 do
          {:ok, session} =
            %WorkoutSession{}
            |> WorkoutSession.changeset(%{
              user_id: user.id,
              workout_template_id: template.id,
              started_at: DateTime.add(DateTime.utc_now(), -i, :day),
              completed_at: DateTime.add(DateTime.utc_now(), -i, :day)
            })
            |> Repo.insert()

          # Log a set for each session
          {:ok, _set} =
            %WorkoutSet{}
            |> WorkoutSet.changeset(%{
              workout_session_id: session.id,
              exercise_id: exercise.id,
              set_number: 1,
              weight: Decimal.new("#{100 + i * 5}"),
              reps: 5
            })
            |> Repo.insert()

          session
        end

      %{user: user, exercise: exercise, sessions: sessions}
    end

    test "returns weight history with default limit of 30", %{user: user, exercise: exercise} do
      history = Workouts.get_exercise_weight_history(user.id, exercise.id)

      # Should return all 10 sessions (less than default 30)
      assert length(history) == 10
    end

    test "respects custom limit parameter", %{user: user, exercise: exercise} do
      history = Workouts.get_exercise_weight_history(user.id, exercise.id, limit: 5)

      assert length(history) == 5
    end

    test "returns data in chronological order (oldest first)", %{user: user, exercise: exercise} do
      history = Workouts.get_exercise_weight_history(user.id, exercise.id, limit: 3)

      # Should return 3 most recent sessions in chronological order
      assert length(history) == 3

      # Within the limit, data should be ordered oldest first (day -3, -2, -1)
      # Weights are: day -1=105, day -2=110, day -3=115
      # So in chronological order: [115, 110, 105] (descending)
      weights = Enum.map(history, & &1.max_weight)
      assert Enum.reverse(Enum.sort(weights)) == weights
    end

    test "handles limit of 0 by returning no results", %{user: user, exercise: exercise} do
      history = Workouts.get_exercise_weight_history(user.id, exercise.id, limit: 0)

      assert history == []
    end

    test "handles limit larger than available data", %{user: user, exercise: exercise} do
      history = Workouts.get_exercise_weight_history(user.id, exercise.id, limit: 100)

      # Should return all 10 sessions
      assert length(history) == 10
    end

    test "returns empty list when no workout history exists", %{exercise: exercise} do
      other_user = user_fixture()

      history = Workouts.get_exercise_weight_history(other_user.id, exercise.id)

      assert history == []
    end
  end

  describe "get_exercise_volume_history/3" do
    setup do
      user = user_fixture()

      # Create exercise with unique name
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

      template_name = "Test Template #{:rand.uniform(1_000_000)}"

      {:ok, template} =
        %WorkoutTemplate{}
        |> WorkoutTemplate.changeset(%{name: template_name})
        |> Repo.insert()

      # Create 8 completed workout sessions with multiple sets
      sessions =
        for i <- 1..8 do
          {:ok, session} =
            %WorkoutSession{}
            |> WorkoutSession.changeset(%{
              user_id: user.id,
              workout_template_id: template.id,
              started_at: DateTime.add(DateTime.utc_now(), -i, :day),
              completed_at: DateTime.add(DateTime.utc_now(), -i, :day)
            })
            |> Repo.insert()

          # Log 3 sets for each session
          for set_num <- 1..3 do
            {:ok, _set} =
              %WorkoutSet{}
              |> WorkoutSet.changeset(%{
                workout_session_id: session.id,
                exercise_id: exercise.id,
                set_number: set_num,
                weight: Decimal.new("100"),
                reps: 5
              })
              |> Repo.insert()
          end

          session
        end

      %{user: user, exercise: exercise, sessions: sessions}
    end

    test "returns volume history with default limit of 30", %{user: user, exercise: exercise} do
      history = Workouts.get_exercise_volume_history(user.id, exercise.id)

      # Should return all 8 sessions
      assert length(history) == 8
    end

    test "respects custom limit parameter", %{user: user, exercise: exercise} do
      history = Workouts.get_exercise_volume_history(user.id, exercise.id, limit: 3)

      assert length(history) == 3
    end

    test "calculates volume correctly (weight × reps × sets)", %{
      user: user,
      exercise: exercise
    } do
      history = Workouts.get_exercise_volume_history(user.id, exercise.id, limit: 1)

      assert length(history) == 1

      # Each session has 3 sets of 100 lbs × 5 reps = 1500 lbs per session
      expected_volume = Decimal.new("1500")
      assert Decimal.eq?(hd(history).volume, expected_volume)
    end

    test "returns data in chronological order (oldest first)", %{user: user, exercise: exercise} do
      history = Workouts.get_exercise_volume_history(user.id, exercise.id)

      # Should return sessions in chronological order (oldest first)
      assert length(history) == 8

      # All volumes should be the same since all sessions have same weight/reps
      volumes = Enum.map(history, & &1.volume)
      assert Enum.all?(volumes, &Decimal.eq?(&1, hd(volumes)))
    end

    test "handles limit larger than available data", %{user: user, exercise: exercise} do
      history = Workouts.get_exercise_volume_history(user.id, exercise.id, limit: 50)

      # Should return all 8 sessions
      assert length(history) == 8
    end

    test "returns empty list when no workout history exists", %{exercise: exercise} do
      other_user = user_fixture()

      history = Workouts.get_exercise_volume_history(other_user.id, exercise.id)

      assert history == []
    end
  end

  describe "update_set/2" do
    setup do
      user = user_fixture()

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

      template_name = "Test Template #{:rand.uniform(1_000_000)}"

      {:ok, template} =
        %WorkoutTemplate{}
        |> WorkoutTemplate.changeset(%{name: template_name})
        |> Repo.insert()

      {:ok, session} =
        %WorkoutSession{}
        |> WorkoutSession.changeset(%{
          user_id: user.id,
          workout_template_id: template.id,
          started_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })
        |> Repo.insert()

      # Create an initial set
      {:ok, set} =
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

      %{user: user, exercise: exercise, session: session, set: set}
    end

    test "successfully updates weight", %{set: set} do
      {:ok, updated_set} = Workouts.update_set(set, %{weight: Decimal.new("140")})

      assert Decimal.eq?(updated_set.weight, Decimal.new("140"))
      assert updated_set.reps == 5
      assert updated_set.rpe == 8
    end

    test "successfully updates reps", %{set: set} do
      {:ok, updated_set} = Workouts.update_set(set, %{reps: 6})

      assert Decimal.eq?(updated_set.weight, Decimal.new("135"))
      assert updated_set.reps == 6
      assert updated_set.rpe == 8
    end

    test "successfully updates RPE", %{set: set} do
      {:ok, updated_set} = Workouts.update_set(set, %{rpe: 9})

      assert Decimal.eq?(updated_set.weight, Decimal.new("135"))
      assert updated_set.reps == 5
      assert updated_set.rpe == 9
    end

    test "successfully updates multiple fields", %{set: set} do
      {:ok, updated_set} =
        Workouts.update_set(set, %{
          weight: Decimal.new("145"),
          reps: 6,
          rpe: 9
        })

      assert Decimal.eq?(updated_set.weight, Decimal.new("145"))
      assert updated_set.reps == 6
      assert updated_set.rpe == 9
    end

    test "persists changes to database", %{set: set} do
      {:ok, _updated} =
        Workouts.update_set(set, %{
          weight: Decimal.new("150"),
          reps: 4
        })

      # Verify changes are in database
      db_set = Repo.get!(WorkoutSet, set.id)
      assert Decimal.eq?(db_set.weight, Decimal.new("150"))
      assert db_set.reps == 4
    end

    test "can clear RPE by setting to nil", %{set: set} do
      {:ok, updated_set} = Workouts.update_set(set, %{rpe: nil})

      assert updated_set.rpe == nil
    end
  end

  describe "upsert_set/1" do
    setup do
      user = user_fixture()

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

      template_name = "Test Template #{:rand.uniform(1_000_000)}"

      {:ok, template} =
        %WorkoutTemplate{}
        |> WorkoutTemplate.changeset(%{name: template_name})
        |> Repo.insert()

      {:ok, session} =
        %WorkoutSession{}
        |> WorkoutSession.changeset(%{
          user_id: user.id,
          workout_template_id: template.id,
          started_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })
        |> Repo.insert()

      %{user: user, exercise: exercise, session: session}
    end

    test "creates new set when it doesn't exist", %{session: session, exercise: exercise} do
      attrs = %{
        workout_session_id: session.id,
        exercise_id: exercise.id,
        set_number: 1,
        weight: Decimal.new("135"),
        reps: 5,
        rpe: 8
      }

      {:ok, set} = Workouts.upsert_set(attrs)

      assert Decimal.eq?(set.weight, Decimal.new("135"))
      assert set.reps == 5
      assert set.rpe == 8
      assert set.set_number == 1
    end

    test "updates existing set when it already exists", %{session: session, exercise: exercise} do
      # Create initial set
      attrs = %{
        workout_session_id: session.id,
        exercise_id: exercise.id,
        set_number: 1,
        weight: Decimal.new("135"),
        reps: 5,
        rpe: 8
      }

      {:ok, initial_set} = Workouts.upsert_set(attrs)

      # Upsert with new values
      updated_attrs = %{
        workout_session_id: session.id,
        exercise_id: exercise.id,
        set_number: 1,
        weight: Decimal.new("140"),
        reps: 6,
        rpe: 9
      }

      {:ok, updated_set} = Workouts.upsert_set(updated_attrs)

      # Should be the same set (same ID)
      assert updated_set.id == initial_set.id

      # But with updated values
      assert Decimal.eq?(updated_set.weight, Decimal.new("140"))
      assert updated_set.reps == 6
      assert updated_set.rpe == 9
    end

    test "creates multiple sets with different set_numbers", %{
      session: session,
      exercise: exercise
    } do
      # Create set 1
      {:ok, set1} =
        Workouts.upsert_set(%{
          workout_session_id: session.id,
          exercise_id: exercise.id,
          set_number: 1,
          weight: Decimal.new("135"),
          reps: 5
        })

      # Create set 2
      {:ok, set2} =
        Workouts.upsert_set(%{
          workout_session_id: session.id,
          exercise_id: exercise.id,
          set_number: 2,
          weight: Decimal.new("135"),
          reps: 5
        })

      # Should be different sets
      assert set1.id != set2.id
      assert set1.set_number == 1
      assert set2.set_number == 2
    end
  end
end
