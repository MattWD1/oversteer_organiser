# Feature: League → Division → Session results vertical slice

---

## 1. Purpose

- Provide an end-to-end flow from selecting a league down to entering results for a specific race session.
- Act as the first working prototype of the core Oversteer Organiser concept: centralised, structured handling of league events and race outcomes.
- Give a concrete foundation to plug in the real database and validation logic later.

---

## 2. Related Requirements

- FR1 – Create and manage leagues (read/view part implemented here).
- FRx – View competitions/divisions within a league.
- FRx – View events (rounds) within a competition/division.
- FRx – Enter results for a race session (prototype implemented via Session results input on `SessionPage`).
- All of these support the overall goal of centralising league management and automating results handling.

---

## 3. Key Files

- **Leagues & competitions**
  - `lib/models/league.dart`
  - `lib/models/competition.dart`
  - `lib/repositories/league_repository.dart`
  - `lib/repositories/competition_repository.dart`
  - `lib/screens/leagues_page.dart`
  - `lib/screens/competitions_page.dart`
- **Events & session**
  - `lib/models/event.dart`
  - `lib/repositories/event_repository.dart`
  - `lib/screens/division_page.dart`
  - `lib/screens/session_page.dart`  ← session results input prototype
- **Entry point**
  - `lib/main.dart` – wires repositories into `LeaguesPage` and starts the vertical flow.

---

## 4. What I Implemented

### 4.1 Leagues → Competitions → Division → Events

- **LeaguesPage**
  - Loads leagues asynchronously via `LeagueRepository` (currently `InMemoryLeagueRepository`).
  - Shows a simple list of leagues with name and organiser.
  - Tapping a league navigates to `CompetitionsPage` for that league.

- **CompetitionsPage**
  - Uses `CompetitionRepository` to load competitions/divisions for the selected league.
  - Displays them in a list with name and season label.
  - Tapping a competition navigates to `DivisionPage` for that competition.

- **DivisionPage**
  - Uses `EventRepository` to load events (rounds) for the selected competition.
  - Shows a list of events such as “Round 1 – Bahrain”.
  - Tapping an event navigates to `SessionPage` for that event.

### 4.2 Session results input (SessionPage)

- **SessionPage (Session result prototype)**
  - Receives an `Event` and displays its name in the app bar.
  - Uses a local list of dummy drivers (`Driver 1`–`Driver 5`) to simulate participants.
  - For each driver, renders two numeric inputs:
    - Grid position.
    - Finish position.
  - Implements `_saveResults()` which:
    - Validates that every driver has a finish position.
    - Validates that finish positions are unique (no duplicates).
    - If validation passes, prints the grid/finish for each driver to the console and shows a snackbar.
  - This behaves as a **functional prototype of the session result entry feature**, to be later backed by real driver data and database persistence.

---

## 5. Important Decisions

- Introduced a **repository pattern** (League, Competition, Event) from the beginning so that:
  - The UI can stay the same when swapping from in-memory data to a real database/API.
  - The vertical slice accurately mirrors the ERD structure without hard-wiring data sources into widgets.
- Kept all layouts **function-first** (lists + simple forms) and postponed styling decisions.
- For the session results feature:
  - Chose to start with dummy drivers and console output so that validation and basic behaviour can be tested before integrating real DRIVER/SESSION_RESULT tables.
  - Implemented simple validation rules on finish positions to echo future validation logic (e.g. no duplicate results, complete entries).

---

## 6. Non-Functional Notes

- **Usability**
  - Straightforward drill-down path: Leagues → Competitions → Division → Events → Session.
  - Each screen has a clear app bar title so the user always knows “where they are” in the hierarchy.
  - SessionPage uses clear numeric inputs with basic error messaging at the top of the screen.
- **Feedback**
  - Loading indicators while data is being fetched from repositories.
  - Error text shown if a repository fails to load data.
  - Snackbar on successful “save” on the session results screen.
- **Extensibility**
  - Each layer (Leagues, Competitions, Events, Session results) already separated by models, repositories and screens, making it easier to extend individually.

---

## 7. Testing Done

- Manual navigation tests:
  - App launches on **My Leagues**.
  - League → Competitions → Division → Events → SessionPage and back using the Android back button.
- Data loading:
  - Confirmed that the correct competitions appear per league using dummy data.
  - Confirmed that the correct events appear per competition using dummy data.
- Session results input (SessionPage – from session result feature):
  - Entered grid and finish positions for all dummy drivers and verified they print correctly to the console.
  - Left one finish position empty and confirmed the validation message is shown.
  - Created duplicate finish positions and confirmed the duplicate warning is shown.
  - Verified that a snackbar appears on successful “save”.

---

## 8. Limitations / TODO

- Repositories are all **in-memory only**; no real database or API integration yet.
- Drivers on SessionPage are dummy entries, not pulled from actual DRIVER/LEAGUE_MEMBERSHIP/SESSION_RESULT entities.
- Session results are not persisted; they are only printed and discarded.
- No points, penalties, or classification logic implemented yet; this is a basic input + validation prototype.
- UI is minimal and not aligned yet with the final Figma designs; styling will be added after core behaviours are stable.

---

## 9. Evidence

- GitHub repository: `oversteer_organiser`.
- Commit: *Initial vertical slice: leagues → competitions → division → events → session input* (contains the first version of the session result input feature on `SessionPage`).
- Future evidence planned: screenshots of each screen in the vertical slice running on a physical device.

---
