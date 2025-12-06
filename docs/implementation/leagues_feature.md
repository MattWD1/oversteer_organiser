# Feature: League → Division → Session results + Issue Log vertical slice

---

## 1. Purpose

- Provide an end-to-end flow from selecting a league down to entering and validating results for a specific race session.
- Act as the first working prototype of the core Oversteer Organiser concept: centralised, structured handling of league events, race outcomes, and validation issues.
- Give a concrete foundation to plug in the real database and validation tables later (e.g. `SESSION_RESULT`, `VALIDATION_ISSUE`), while still developing quickly with in-memory data.

---

## 2. Related Requirements

- **FR1** – Create and manage leagues (read/view part implemented here).
- **FRx** – View competitions/divisions within a league.
- **FRx** – View events (rounds) within a competition/division.
- **FRx** – Enter results for a race session.
- **FRx** – Validate and log issues with race results (prototype implemented via validation and Issue Log).

All of these support the overarching goal of centralising sim-racing league management and automating results handling and validation.

---

## 3. Key Files

### 3.1 Models

- `lib/models/league.dart`
- `lib/models/competition.dart`
- `lib/models/division.dart`
- `lib/models/event.dart`
- `lib/models/driver.dart`
- `lib/models/session_result.dart`
- `lib/models/validation_issue.dart`

### 3.2 Repositories (in-memory prototypes)

- `lib/repositories/league_repository.dart`
  - `LeagueRepository`, `InMemoryLeagueRepository`
- `lib/repositories/competition_repository.dart`
  - `CompetitionRepository`, `InMemoryCompetitionRepository`
- `lib/repositories/event_repository.dart`
  - `EventRepository`, `InMemoryEventRepository`
- `lib/repositories/driver_repository.dart`
  - `DriverRepository`, `InMemoryDriverRepository`
- `lib/repositories/session_result_repository.dart`
  - `SessionResultRepository` (stores results per `eventId` in memory)
- `lib/repositories/validation_issue_repository.dart`
  - `ValidationIssueRepository` (stores validation issues per `eventId` in memory)

### 3.3 Screens

- Navigation:
  - `lib/screens/leagues_page.dart`
  - `lib/screens/competitions_page.dart`
  - `lib/screens/divisions_page.dart`
  - `lib/screens/events_page.dart`
- Session + validation:
  - `lib/screens/session_page.dart`  ← main session result input and validation
  - `lib/screens/issue_log_page.dart` ← shows validation issues per event

### 3.4 Entry point

- `lib/main.dart`
  - Creates the in-memory repositories.
  - Wires them into `LeaguesPage` so the vertical slice starts from **My Leagues**.

---

## 4. What I Implemented

### 4.1 Leagues → Competitions → Divisions → Events

**LeaguesPage**

- Uses `LeagueRepository` (`InMemoryLeagueRepository`) to load leagues for the current user.
- Displays leagues in a list with league name and organiser.
- Tapping a league navigates to `CompetitionsPage`, passing:
  - Selected `League`
  - `CompetitionRepository`
  - `EventRepository`
  - `DriverRepository`
  - `SessionResultRepository`
  - `ValidationIssueRepository`

**CompetitionsPage**

- Uses `CompetitionRepository` to load competitions for the selected league.
- Displays competition name and season.
- Tapping a competition navigates to `DivisionsPage`, passing:
  - Selected `League` and `Competition`
  - `CompetitionRepository`
  - `EventRepository`
  - `DriverRepository`
  - `SessionResultRepository`
  - `ValidationIssueRepository`

**DivisionsPage**

- Uses `CompetitionRepository.getDivisionsForCompetition(competition.id)` to load divisions for the selected competition.
- Displays division names (e.g. Tier 1, Tier 2).
- Tapping a division navigates to `EventsPage`, passing:
  - Selected `League`, `Competition`, `Division`
  - `EventRepository`
  - `DriverRepository`
  - `SessionResultRepository`
  - `ValidationIssueRepository`

**EventsPage**

- Uses `EventRepository.getEventsForDivision(division.id)` to load events for the selected division.
- Displays list items such as “Round 1 – Bahrain” with the event date.
- Each event row:
  - Chevron → opens `SessionPage` (result entry) for that event.
  - Warning icon → opens `IssueLogPage` to view validation issues for that event.

This creates a full drill-down path:

> `Leagues → Competitions → Divisions → Events → Session (Results + Validation)`

---

### 4.2 Session results input and validation (`SessionPage`)

**SessionPage responsibilities**

- Receives:
  - `Event event`
  - `DriverRepository`
  - `SessionResultRepository`
  - `ValidationIssueRepository`
- On load:
  - Calls `driverRepository.getDriversForEvent(event.id)` to fetch drivers for the chosen event.
  - Calls `sessionResultRepository.getResultsForEvent(event.id)` to load any previously saved results.
  - Builds a `Map<String, SessionResult>` (`_resultsByDriverId`) so every driver has a `SessionResult` object keyed by `driverId`.
  - Creates two `TextEditingController`s per driver:
    - One for **Grid** position.
    - One for **Finish** position.
  - Pre-populates controllers from any existing results.

**UI**

- Displays a scrollable list of drivers.
- Each row shows:
  - Driver name.
  - Two numeric text fields:
    - **Grid** – starting grid position.
    - **Finish** – classified finishing position.
- A **Save Results** button at the bottom:
  - Disabled while `_isSaving` is true.
  - Shows a `CircularProgressIndicator` while saving.

**On change**

- `onChanged` for the Grid field calls `_updateGridPosition(driver.id, value)`:
  - Parses the number and updates `_resultsByDriverId[driverId].gridPosition`.
- `onChanged` for the Finish field calls `_updateFinishPosition(driver.id, value)`:
  - Parses the number and updates `_resultsByDriverId[driverId].finishPosition`.

---

### 4.3 Validation rules and issue logging

When **Save Results** is tapped, `SessionPage` runs `_validateResults()` before saving anything.

Current rules:

1. **Missing data**
   - Every driver must have:
     - A `gridPosition` (can be `null` in model but is treated as invalid).
     - A `finishPosition`.
   - If missing:
     - Creates a `ValidationIssue` per missing field, e.g.:
       - `code: 'MISSING_GRID'`, message: “Missing GRID position for Lando Norris.”
       - `code: 'MISSING_FINISH'`, message: “Missing FINISH position for Charles Leclerc.”

2. **Duplicate Grid positions**
   - Builds a map of `gridPosition → [drivers]`.
   - If two or more drivers share the same grid position:
     - Creates a `ValidationIssue` with:
       - `code: 'DUPLICATE_GRID'`
       - Message: e.g. “Duplicate GRID position 3 for: Driver A, Driver B.”

3. **Duplicate Finish positions**
   - Builds a map of `finishPosition → [drivers]`.
   - If two or more drivers share the same finish position:
     - Creates a `ValidationIssue` with:
       - `code: 'DUPLICATE_FINISH'`
       - Message: e.g. “Duplicate FINISH position 1 for: Driver A, Driver B.”

4. **Invalid Finish range**
   - For each driver:
     - Checks `finishPosition` is within `1..numberOfDrivers`.
   - If out of range:
     - Creates a `ValidationIssue` with:
       - `code: 'INVALID_FINISH_RANGE'`
       - Message: e.g. “Finish position for Carlos Sainz should be between 1 and 20.”

**ValidationIssue model**

- `id` – generated string containing `eventId`, type and timestamp.
- `eventId` – links to the `EVENT` in the ERD.
- `driverId` – optional; present for driver-specific issues.
- `code` – short machine-friendly identifier (`MISSING_GRID`, `DUPLICATE_FINISH`, etc.).
- `message` – human-readable explanation.
- `createdAt` – `DateTime` when the issue was detected.
- `isResolved` – reserved for later, default `false`.

**Saving issues and results**

- After building the list of `ValidationIssue`s:
  - If there are issues:
    - `validationIssueRepository.replaceIssuesForEvent(event.id, issues)` is called.
    - A dialog appears listing each issue as a bullet point.
    - Results are **not** saved; the user must fix issues and press Save again.
  - If there are no issues:
    - `validationIssueRepository.clearIssuesForEvent(event.id)` is called.
    - All `SessionResult` objects from `_resultsByDriverId` are saved via:
      - `sessionResultRepository.saveResultsForEvent(event.id, results)`.
    - A snackbar “Session results saved” is shown.

This behaviour matches the idea of **automated result validation feeding into a validation issue log** aligned with the FYP’s `VALIDATION_ISSUE` table.

---

### 4.4 Issue Log screen (`IssueLogPage`)

- `IssueLogPage` receives:
  - `Event event`
  - `ValidationIssueRepository`
- On build:
  - Calls `validationIssueRepository.getIssuesForEvent(event.id)`.
  - If no issues:
    - Shows “No validation issues for this event.”
  - If issues exist:
    - Displays each `ValidationIssue` as a `ListTile`:
      - Leading icon: warning/error icon.
      - Title: the `message` (e.g. “Duplicate FINISH position 1 for: …”).
      - Subtitle: `code` and timestamp.

**Navigation**

- Accessible from `EventsPage` via a warning icon (`Icons.warning_amber_outlined`) on each event row.
- Gives organisers a central “Issue Log” for each event, which is the UI reflection of the `VALIDATION_ISSUE` concept from the ERD.

---

## 5. Important Decisions

- **Repository pattern everywhere**
  - All data access (leagues, competitions, divisions, events, drivers, session results, validation issues) is abstracted behind repositories.
  - UI code does not depend on how data is stored (in-memory now, Firestore/SQL later).

- **SessionResult + ValidationIssue as first-class models**
  - `SessionResult` ensures that results are stored in a structured, event-scoped format.
  - `ValidationIssue` formalises what used to be plain error strings:
    - Now each problem has an ID, code, message, event, driver, and timestamp.
    - This aligns directly with planned tables like `SESSION_RESULT` and `VALIDATION_ISSUE`.

- **Fail-fast validation**
  - Session results are only saved if **all** validation checks pass.
  - Any issues block the save, are stored in the issue log, and are shown to the organiser immediately.

- **Functionality before styling**
  - Screens currently use basic Material UI components.
  - Styling to match Figma designs, theming, and iconography will be layered on once core behaviours are stabilised.

---

## 6. Non-Functional Notes

- **Usability**
  - Clear breadcrumb-style navigation via app bar titles:
    - “My Leagues” → “Competitions – {League}” → “Divisions – {Competition}” → “Events – {Division}” → “Results – {Event}”.
  - Simple numeric inputs labelled “Grid” and “Finish” on the Session page.

- **Feedback**
  - Async loads show `CircularProgressIndicator`.
  - Errors are displayed as text.
  - Validation issues:
    - Immediate dialog on save attempt.
    - Persisted in the Issue Log per event.
  - Successful saves show a snackbar.

- **Extensibility**
  - Easy to extend validation with:
    - Penalty checks.
    - Safety car / DNF rules.
    - Track limits or steward appeal logic.
  - Easy to hook repositories up to a real database:
    - Replace in-memory maps with Firestore/SQL queries.
    - Keep the same screen logic.

---

## 7. Testing Done

- **Navigation**
  - App starts at **My Leagues**.
  - Tapping through works as expected:
    - Leagues → Competitions → Divisions → Events → Session.
  - Back navigation correctly returns up the stack.

- **Data loading**
  - Competitions filtered by league.
  - Divisions filtered by competition.
  - Events filtered by division.
  - Drivers correctly loaded per event and shown in SessionPage.

- **Validation**
  - **Missing values**
    - Leaving Grid or Finish empty for any driver → issues generated and shown.
  - **Duplicate Grid**
    - Setting the same grid position for two drivers → `DUPLICATE_GRID` issue generated.
  - **Duplicate Finish**
    - Setting the same finish position for two drivers → `DUPLICATE_FINISH` issue generated.
  - **Invalid Finish range**
    - Setting finish to 0 or > number of drivers → `INVALID_FINISH_RANGE` issue generated.
  - **No issues**
    - Valid grid/finish data across all drivers → results saved and Issue Log cleared.

- **Issue Log**
  - After a failed save, Issue Log for that event shows the same issues as the dialog.
  - After fixing and saving successfully, Issue Log reports no issues.

---

## 8. Limitations / TODO

- All repositories are still **in-memory only**:
  - No real persistence between app launches.
- No concept yet of “resolved” validation issues in the UI:
  - `isResolved` exists on `ValidationIssue` but is not toggled anywhere.
- No integration with:
  - Points calculation.
  - Championships/standings tables.
  - Penalties, safety cars, or steward decisions.
- UI is functional but not visually aligned with final designs:
  - No custom theming, branding or track/flag icons yet.
- No authentication / RBAC yet:
  - The current vertical slice assumes the “current user” and admin context.

---

## 9. Evidence

- GitHub repository: `oversteer_organiser`.
- Key commits:
  - Initial vertical slice: Leagues → Competitions → Divisions → Events → Session (basic results input).
  - Add SessionResult + ValidationIssue models and repositories.
  - Wire ValidationIssueRepository and IssueLogPage; add validation for grid/finish data and duplicate detection.
- Planned evidence:
  - Screenshots of:
    - LeaguesPage
    - CompetitionsPage
    - DivisionsPage
    - EventsPage (with Issue Log icon)
    - SessionPage (with validation dialog)
    - IssueLogPage (showing logged issues).

