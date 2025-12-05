# Feature: League → Division → Session results vertical slice

---

## 1. Purpose

- Provide an end-to-end flow from selecting a league down to entering results for a specific race session.
- Act as the first working prototype of the core Oversteer Organiser concept: centralised, structured handling of league events and race outcomes.
- Give a concrete foundation to plug in the real database and validation logic later, while still developing quickly with in-memory data.

---

## 2. Related Requirements

- **FR1** – Create and manage leagues (read/view part implemented here).
- **FRx** – View competitions/divisions within a league.
- **FRx** – View events (rounds) within a competition/division.
- **FRx** – Enter results for a race session (prototype implemented via the Session results input on `SessionPage`).

All of these support the overarching goal of centralising sim racing league management and automating results handling.

---

## 3. Key Files

- **Leagues & competitions**
  - `lib/models/league.dart`
  - `lib/models/competition.dart`
  - `lib/repositories/league_repository.dart`
  - `lib/repositories/competition_repository.dart`
  - `lib/screens/leagues_page.dart`
  - `lib/screens/competitions_page.dart`

- **Events, drivers & session**
  - `lib/models/event.dart`
  - `lib/models/driver.dart`
  - `lib/repositories/event_repository.dart`
  - `lib/repositories/driver_repository.dart`
  - `lib/screens/division_page.dart`
  - `lib/screens/session_page.dart`  ← contains the session result input prototype

- **Entry point**
  - `lib/main.dart` – creates the in-memory repositories and wires them into `LeaguesPage` to start the vertical flow.

---

## 4. What I Implemented

### 4.1 Leagues → Competitions → Division → Events

- **LeaguesPage**
  - Uses `LeagueRepository` (currently `InMemoryLeagueRepository`) to load leagues for the current user.
  - Displays leagues in a simple list with league name and organiser.
  - Tapping a league navigates to `CompetitionsPage`, passing the selected `League` and all relevant repositories.

- **CompetitionsPage**
  - Uses `CompetitionRepository` to load competitions/divisions for the selected league.
  - Displays competitions with a name and season label.
  - Tapping a competition navigates to `DivisionPage`, passing the selected `Competition` plus `EventRepository` and `DriverRepository`.

- **DivisionPage**
  - Uses `EventRepository` to load events (rounds) for the selected competition.
  - Shows events such as “Round 1 – Bahrain”.
  - Tapping an event navigates to `SessionPage`, passing the `Event` and `DriverRepository`.

This provides a clean drill-down path:
`Leagues → Competitions → Division → Events → Session`.

### 4.2 Session results input (SessionPage – session result prototype)

- **SessionPage**
  - Receives an `Event` and a `DriverRepository`.
  - On load, calls `getDriversForEvent(event.id)` on `DriverRepository` (currently `InMemoryDriverRepository`) to fetch drivers for the session.
  - Transforms each `Driver` into an internal `_DriverResult` object containing:
    - `driverId`
    - `driverName`
    - `gridPosition` (nullable, filled by user)
    - `finishPosition` (nullable, filled by user)
  - Renders a scrollable list where each row shows:
    - Driver name.
    - Two numeric text fields:
      - **Grid** position input.
      - **Finish** position input.

- **Validation and behaviour**
  - When the user taps **Save (console only for now)**:
    - Validates that **every** driver has a finish position.
    - Validates that finish positions are **unique** (no duplicates).
    - If validation fails, a red validation message is shown at the top of the screen.
    - If validation passes:
      - Clears the validation message.
      - Prints each driver’s `driverId`, `driverName`, `gridPosition` and `finishPosition` to the console.
      - Shows a snackbar confirming that results were collected (but not yet stored in a database).

This screen is the first functional prototype of the **session result entry feature**, now working with a proper `Driver` model rather than placeholder names.

---

## 5. Important Decisions

- **Repository pattern from the start**
  - Leagues, competitions, events, and drivers are all accessed via repositories (`LeagueRepository`, `CompetitionRepository`, `EventRepository`, `DriverRepository`).
  - This separation allows the UI to remain almost unchanged when switching from in-memory lists to a real database or API.

- **Driver model instead of anonymous names**
  - Introduced a `Driver` model and `DriverRepository` so that results are attached to real driver identities (ID, display name, car number, nationality code).
  - This mirrors the planned ERD entities and prepares the app for proper standings, penalties, and validation rules per driver.

- **Functionality first, styling later**
  - All screens currently use minimal Material components (lists, text, basic inputs).
  - Visual design and alignment to Figma will be tackled after the main behaviours and flows are stable.

- **Early validation within the session result flow**
  - Implemented simple rules (no missing finish positions, no duplicate finishes) at an early stage.
  - This helps test the “feel” of result validation before building the full validation engine and mapping to `VALIDATION_ISSUE` entities in the database.

---

## 6. Non-Functional Notes

- **Usability**
  - Clear hierarchical navigation with consistent app bar titles:
    - “My Leagues” → league name → competition name → event name.
  - SessionPage uses plain number fields with labels “Grid” and “Finish”, which are easy to understand for racing users.

- **Feedback**
  - Each async load (leagues, competitions, events, drivers) shows a `CircularProgressIndicator` while waiting.
  - Any loading error displays a simple text message.
  - Validation errors on SessionPage show as red text above the list.
  - Successful result collection triggers a snackbar.

- **Extensibility**
  - The current vertical slice already separates:
    - Models
    - Repositories
    - Screens
  - That structure will make it easier to:
    - Replace in-memory repositories with real DB-backed ones.
    - Extend SessionPage to handle more fields (penalties, fastest lap, DNFs, etc.).
    - Add new screens (e.g. standings, driver profiles) without redesigning the whole flow.

---

## 7. Testing Done

- **Navigation tests**
  - App launches to **My Leagues**.
  - Tap league → navigates to **Competitions**.
  - Tap competition → navigates to **Division** (events list).
  - Tap event → navigates to **SessionPage**.
  - Back button correctly unwinds the stack back to the home screen.

- **Data loading tests**
  - Verified that competitions filter correctly by league using in-memory data.
  - Verified that events filter correctly by competition.
  - Verified that drivers load from `InMemoryDriverRepository` and display correctly on SessionPage.

- **SessionPage validation tests**
  - Entered different grid/finish combinations and confirmed they print correctly to the console.
  - Left one finish position blank → correct validation message shown.
  - Used duplicate finish positions → duplicate warning shown.
  - Correct data + Save → snackbar appears confirming results collection.

---

## 8. Limitations / TODO

- All repositories (`League`, `Competition`, `Event`, `Driver`) are currently **in-memory only**; nothing is persisted between runs.
- Session results are not yet represented by a dedicated `SessionResult` model or stored anywhere; they are only printed.
- No integration yet with:
  - Points calculation.
  - Penalties.
  - Standings or leaderboards.
- Grid positions are collected but not validated or used for any logic.
- UI is functional but not styled to match the final Figma designs:
  - No theming beyond basic Material colours.
  - No icons/graphics for tracks, teams or national flags yet.

---

## 9. Evidence

- GitHub repository: `oversteer_organiser`.
- Commits (examples):
  - *Initial vertical slice: leagues → competitions → division → events → session input* – first working flow and initial SessionPage.
  - *Add Driver model and DriverRepository, and wire into SessionPage* – switches SessionPage from hard-coded driver names to the proper driver model and repository.
- Future evidence planned:
  - Screenshots of each screen in the vertical slice (Leagues, Competitions, Division, Events, Session) running on a physical device.

---
