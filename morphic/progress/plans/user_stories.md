# User Stories - Stronk

User stories for the Stronk workout tracking application.

## Epic: User Authentication & Onboarding

### US-001: User Registration
**As a** new user
**I want to** create an account with my email
**So that** I can start tracking my workouts

**Acceptance Criteria:**
- User can register with email address
- Password is securely hashed (bcrypt)
- User receives confirmation email (magic link)
- User is redirected to dashboard after confirmation
- Error messages shown for invalid email or existing account

**Status:** ✅ Implemented

---

### US-002: User Login
**As a** returning user
**I want to** log in with my email
**So that** I can access my workout history

**Acceptance Criteria:**
- User can log in with email (magic link)
- Session persists across page refreshes
- User is redirected to dashboard after login
- Error messages shown for invalid credentials

**Status:** ✅ Implemented

---

## Epic: Workout Management

### US-003: View Dashboard
**As a** user
**I want to** see my workout overview on the dashboard
**So that** I can track my progress and choose my next workout

**Acceptance Criteria:**
- Dashboard shows total workouts completed
- Dashboard shows current week streak
- Dashboard shows last workout date
- User can see Workout A and Workout B options
- User can start a new workout from dashboard

**Status:** ✅ Implemented

---

### US-004: Start Workout Session
**As a** user
**I want to** start a workout session (A or B)
**So that** I can log my sets and track my progress

**Acceptance Criteria:**
- User can select Workout A or Workout B
- Session is created with started_at timestamp
- User is redirected to active workout screen
- Only one workout can be active at a time
- Workout template exercises are loaded

**Status:** ✅ Implemented

---

### US-005: Log Exercise Sets
**As a** user
**I want to** log my weight and reps for each set
**So that** I can track my strength gains over time

**Acceptance Criteria:**
- User can enter weight (lbs or kg)
- User can enter reps completed
- User can optionally enter RPE (Rate of Perceived Exertion)
- Sets are saved immediately
- User can see all logged sets for current exercise
- User can see suggested weight based on last workout

**Status:** ✅ Implemented

---

### US-006: View Suggested Weights
**As a** user
**I want to** see suggested weights based on my previous workout
**So that** I can apply progressive overload

**Acceptance Criteria:**
- System shows weight from last completed set for same exercise
- Suggested weight is clearly displayed before logging new set
- User can easily use suggested weight or enter custom amount
- Progressive overload recommendations (e.g., +5 lbs)

**Status:** ✅ Implemented

---

### US-007: Complete Workout
**As a** user
**I want to** mark my workout as complete
**So that** it's saved to my history

**Acceptance Criteria:**
- User can complete workout from active session
- Workout is saved with completed_at timestamp
- User sees completion confirmation
- User is redirected to workout history or dashboard
- Workout appears in history immediately

**Status:** ✅ Implemented

---

## Epic: Progress Tracking

### US-008: View Workout History
**As a** user
**I want to** see my past workouts
**So that** I can review my training consistency

**Acceptance Criteria:**
- History shows all completed workouts chronologically
- Each workout shows date, template (A or B), and duration
- User can tap/click workout to see details
- History shows most recent workouts first
- Empty state shown when no workouts exist

**Status:** ✅ Implemented

---

### US-009: View Workout Details
**As a** user
**I want to** see detailed information about a past workout
**So that** I can review what I did

**Acceptance Criteria:**
- Details show all exercises performed
- Each exercise shows sets, reps, weight, and RPE
- Details show workout date and duration
- User can compare with previous session
- User can navigate back to history

**Status:** ✅ Implemented

---

### US-010: Track Progress Charts
**As a** user
**I want to** see visual charts of my strength progress
**So that** I can see my gains over time

**Acceptance Criteria:**
- Charts show weight progression per exercise
- Charts show volume (sets × reps × weight) over time
- User can filter by exercise
- User can select date range
- Charts are mobile-friendly

**Status:** ✅ Implemented

---

## Epic: Mobile Experience

### US-011: Mobile-First Design
**As a** user in the gym
**I want to** use the app on my phone
**So that** I can log workouts easily while training

**Acceptance Criteria:**
- App is fully responsive on mobile devices
- Touch targets are minimum 44px (thumb-friendly)
- App works in portrait orientation
- Text is readable without zooming
- Forms are easy to fill on mobile

**Status:** ✅ Implemented

---

### US-012: PWA Installation
**As a** user
**I want to** install the app on my phone
**So that** it feels like a native app

**Acceptance Criteria:**
- App can be installed as PWA
- App icon appears on home screen
- App opens in standalone mode (no browser UI)
- App manifest is properly configured
- App works offline (basic functionality)

**Status:** ✅ Implemented

---

## Epic: Data Management

### US-013: Edit Logged Set
**As a** user
**I want to** edit a set I just logged
**So that** I can correct mistakes

**Acceptance Criteria:**
- User can edit weight, reps, RPE of logged set
- Changes are saved immediately
- User sees confirmation of update
- Edit is only available during active workout

**Status:** ✅ Implemented

---

### US-014: Delete Logged Set
**As a** user
**I want to** delete a set I logged by mistake
**So that** my data is accurate

**Acceptance Criteria:**
- User can delete a logged set
- User sees confirmation before deletion
- Set is removed from workout
- Delete is only available during active workout

**Status:** ✅ Implemented

---

### US-015: Export Workout Data
**As a** user
**I want to** export my workout history
**So that** I can back up my data or analyze it elsewhere

**Acceptance Criteria:**
- User can export data as CSV or JSON
- Export includes all workouts and sets
- Export preserves dates, weights, reps, RPE
- User can download file

**Status:** ❌ Not Implemented

---

## Epic: User Preferences

### US-016: Set Weight Units
**As a** user
**I want to** choose between lbs and kg
**So that** I can use my preferred unit system

**Acceptance Criteria:**
- User can select lbs or kg in settings
- Setting persists across sessions
- All weights display in selected unit
- Conversion is accurate

**Status:** ✅ Implemented

---

### US-017: Dark/Light Mode
**As a** user
**I want to** choose between dark and light themes
**So that** the app is comfortable to use in different environments

**Acceptance Criteria:**
- User can toggle dark/light mode
- User can select "system" to follow device preference
- Theme preference persists
- All screens support both themes
- Smooth transition between themes

**Status:** ✅ Implemented

---

## Epic: Workout Customization

### US-018: Add Rest Timer
**As a** user
**I want to** see a rest timer between sets
**So that** I can maintain consistent rest periods

**Acceptance Criteria:**
- Timer starts automatically after logging set
- User can customize rest duration
- Timer shows countdown
- Audio/vibration notification when timer completes
- User can skip or reset timer

**Status:** ✅ Implemented

**Implementation Notes:**
- In-workout duration picker (1:00, 1:30, 2:00, 3:00)
- Reset button to restore initial duration
- Audio beep (800Hz, 0.5s) on completion
- Vibration pattern (200-100-200ms) for mobile
- Auto-advance to next exercise when all sets complete
- Custom duration persists throughout session

---

### US-019: Add Workout Notes
**As a** user
**I want to** add notes to my workout
**So that** I can remember how I felt or any issues

**Acceptance Criteria:**
- User can add text notes to workout session
- Notes are saved with workout
- Notes are visible in workout history
- User can edit notes

**Status:** ✅ Implemented

---

### US-020: Custom Exercises
**As a** user
**I want to** add custom exercises to my workout
**So that** I can track accessory work

**Acceptance Criteria:**
- User can create custom exercises
- Custom exercises have name and optional notes
- User can add custom exercises to active workout
- Custom exercises persist across sessions
- User can delete custom exercises

**Status:** ❌ Not Implemented

---

## Priority Matrix

### P0 - Critical (MVP)
- [x] US-001: User Registration
- [x] US-002: User Login
- [x] US-003: View Dashboard
- [x] US-004: Start Workout Session
- [x] US-005: Log Exercise Sets
- [x] US-008: View Workout History
- [x] US-011: Mobile-First Design

### P1 - High Priority
- [x] US-006: View Suggested Weights (improve with progressive overload)
- [x] US-010: Track Progress Charts
- [x] US-013: Edit Logged Set
- [x] US-014: Delete Logged Set
- [x] US-018: Add Rest Timer

### P2 - Medium Priority
- [x] US-012: PWA Installation (offline support)
- [x] US-016: Set Weight Units
- [x] US-019: Add Workout Notes

### P3 - Low Priority
- [ ] US-015: Export Workout Data
- [ ] US-020: Custom Exercises

---

## Notes

**Current Focus:**
- Improving progressive overload suggestions
- Adding progress charts
- Implementing edit/delete functionality for sets

**Technical Debt:**
- Need to generate actual PNG favicons
- Performance optimization for large workout histories

**Future Enhancements:**
- Social features (share workouts)
- Workout reminders/notifications
- Integration with fitness trackers
- Plate calculator (which plates to load on barbell)

---

**Last Updated:** 2026-01-03
