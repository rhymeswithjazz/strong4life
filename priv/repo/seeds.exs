# Script for populating the database with the Strong for Life workout program.
#
# You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Strong4life.Repo.insert!(%Strong4life.SomeSchema{})
#
# This file is idempotent - it can be run multiple times without creating duplicates.

alias Strong4life.Repo
alias Strong4life.Workouts.{Exercise, WorkoutTemplate, WorkoutTemplateExercise}

IO.puts("🏋️ Seeding Strong for Life workout program...")

# ============================================
# Define Exercises
# ============================================

exercises = [
  # Compound Exercises
  %{
    name: "Barbell Squat",
    category: "compound",
    instructions: "Focus on depth and control. Go as deep as you can with good form (chest up, back straight). Keep your core braced throughout the movement.",
    default_sets: 3,
    default_reps: 5,
    is_accessory: false
  },
  %{
    name: "Barbell Bench Press",
    category: "compound",
    instructions: "Keep your shoulder blades retracted and your feet planted firmly on the floor. Lower the bar with control to your chest, then press up explosively.",
    default_sets: 3,
    default_reps: 5,
    is_accessory: false
  },
  %{
    name: "Barbell Row",
    category: "compound",
    instructions: "Keep your back flat and pull the bar towards your lower chest/stomach. Squeeze your shoulder blades together at the top of the movement.",
    default_sets: 3,
    default_reps: 8,
    is_accessory: false
  },
  %{
    name: "Barbell Overhead Press",
    category: "compound",
    instructions: "Brace your core and glutes. Don't lean back too much. Press the bar straight up, moving your head back slightly to allow the bar path.",
    default_sets: 3,
    default_reps: 5,
    is_accessory: false
  },
  %{
    name: "Barbell Deadlift",
    category: "compound",
    instructions: "Keep your back flat and chest up. Push through your heels and drive your hips forward. Consider Romanian Deadlifts (RDLs) for less lower back strain.",
    default_sets: 3,
    default_reps: 5,
    is_accessory: false
  },
  %{
    name: "Close Grip Bench Press",
    category: "compound",
    instructions: "Use a grip slightly narrower than shoulder width. This variation emphasizes the triceps more while still working the chest.",
    default_sets: 3,
    default_reps: 8,
    is_accessory: false
  },

  # Accessory Exercises
  %{
    name: "Face Pulls",
    category: "accessory",
    instructions: "Pull the rope towards your face, focusing on external rotation at the shoulders. Excellent for shoulder health and rear delt development.",
    default_sets: 3,
    default_reps: 15,
    is_accessory: true
  },
  %{
    name: "Plank",
    category: "accessory",
    instructions: "Hold a straight body position from head to heels. Keep your core tight and don't let your hips sag or pike up.",
    default_sets: 3,
    default_reps: 45,  # Seconds
    is_accessory: true
  },
  %{
    name: "Dumbbell Lunges",
    category: "accessory",
    instructions: "Take a controlled step forward, lowering your back knee towards the ground. Keep your torso upright throughout the movement.",
    default_sets: 3,
    default_reps: 10,
    is_accessory: true
  },
  %{
    name: "Hanging Knee Raises",
    category: "accessory",
    instructions: "Hang from a bar and raise your knees towards your chest. Control the movement and avoid swinging.",
    default_sets: 3,
    default_reps: 12,
    is_accessory: true
  }
]

# Insert or update exercises
exercise_map =
  Enum.reduce(exercises, %{}, fn exercise_attrs, acc ->
    case Repo.get_by(Exercise, name: exercise_attrs.name) do
      nil ->
        {:ok, exercise} =
          %Exercise{}
          |> Exercise.changeset(exercise_attrs)
          |> Repo.insert()
        Map.put(acc, exercise_attrs.name, exercise)

      existing ->
        {:ok, exercise} =
          existing
          |> Exercise.changeset(exercise_attrs)
          |> Repo.update()
        Map.put(acc, exercise_attrs.name, exercise)
    end
  end)

IO.puts("✅ Created/updated #{map_size(exercise_map)} exercises")

# ============================================
# Define Workout Templates
# ============================================

workout_a_exercises = [
  {"Barbell Squat", 1, 3, 5},
  {"Barbell Bench Press", 2, 3, 5},
  {"Barbell Row", 3, 3, 8},
  {"Face Pulls", 4, 3, 15}
]

workout_b_exercises = [
  {"Barbell Overhead Press", 1, 3, 5},
  {"Barbell Deadlift", 2, 3, 5},
  {"Close Grip Bench Press", 3, 3, 8},
  {"Dumbbell Lunges", 4, 3, 10}
]

# Create Workout A
workout_a =
  case Repo.get_by(WorkoutTemplate, name: "Workout A") do
    nil ->
      {:ok, template} =
        %WorkoutTemplate{}
        |> WorkoutTemplate.changeset(%{
          name: "Workout A",
          description: "Full body workout focusing on Squat, Bench Press, and Rows. Include Face Pulls for shoulder health."
        })
        |> Repo.insert()
      template

    existing ->
      existing
  end

# Create Workout B
workout_b =
  case Repo.get_by(WorkoutTemplate, name: "Workout B") do
    nil ->
      {:ok, template} =
        %WorkoutTemplate{}
        |> WorkoutTemplate.changeset(%{
          name: "Workout B",
          description: "Full body workout focusing on Overhead Press, Deadlift, and Close Grip Bench. Include Lunges for leg accessory work."
        })
        |> Repo.insert()
      template

    existing ->
      existing
  end

IO.puts("✅ Created/updated workout templates")

# ============================================
# Link Exercises to Templates
# ============================================

# Helper function to upsert template exercises
upsert_template_exercise = fn template, {exercise_name, order, sets, reps} ->
  exercise = exercise_map[exercise_name]

  case Repo.get_by(WorkoutTemplateExercise,
         workout_template_id: template.id,
         exercise_id: exercise.id
       ) do
    nil ->
      %WorkoutTemplateExercise{}
      |> WorkoutTemplateExercise.changeset(%{
        workout_template_id: template.id,
        exercise_id: exercise.id,
        order: order,
        target_sets: sets,
        target_reps: reps
      })
      |> Repo.insert!()

    existing ->
      existing
      |> WorkoutTemplateExercise.changeset(%{
        order: order,
        target_sets: sets,
        target_reps: reps
      })
      |> Repo.update!()
  end
end

# Link exercises to Workout A
Enum.each(workout_a_exercises, &upsert_template_exercise.(workout_a, &1))
IO.puts("✅ Linked #{length(workout_a_exercises)} exercises to Workout A")

# Link exercises to Workout B
Enum.each(workout_b_exercises, &upsert_template_exercise.(workout_b, &1))
IO.puts("✅ Linked #{length(workout_b_exercises)} exercises to Workout B")

IO.puts("")
IO.puts("🎉 Strong for Life workout program seeded successfully!")
IO.puts("")
IO.puts("Workout Schedule:")
IO.puts("  Week 1: Mon (A), Wed (B), Fri (A)")
IO.puts("  Week 2: Mon (B), Wed (A), Fri (B)")
IO.puts("")
