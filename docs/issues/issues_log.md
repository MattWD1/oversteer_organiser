# Issues Log

---

## Issue 1 – Flutter screen stuck on phone

- **Date:** 2025-12-05  
- **Area:** Setup / First Run  
- **Description:** When running an AI-generated scrap Flutter project, the app only showed the Flutter splash screen on the phone and then appeared stuck.  
- **Cause:** The generated project code was incomplete / broken. The problem was not with Flutter tooling or the physical device, but with the example project itself.  
- **Fix:** Created a clean Flutter project and replaced `main.dart` with a very simple test app. Confirmed that the test page ran successfully on the phone, proving the toolchain and device setup were correct.

---

## Issue 2 – `leagues_page.dart` import / missing file

- **Date:** 2025-12-05  
- **Area:** Project structure / Screens  
- **Description:** Error: “Target of URI doesn't exist: `screens/leagues_page.dart`” and “The method `LeaguesPage` isn't defined for the type `OversteerApp`.”  
- **Cause:** `main.dart` imported `screens/leagues_page.dart` and used `LeaguesPage`, but the file and widget did not exist yet under `lib/screens`.  
- **Fix:** Created `lib/screens/leagues_page.dart` with a `LeaguesPage` widget and added the correct imports. After saving, the missing file and undefined method errors were resolved.

---

## Issue 3 – `MyApp` not found in `widget_test.dart`

- **Date:** 2025-12-05  
- **Area:** Testing / Default Flutter test  
- **Description:** Error in `test/widget_test.dart`: “The name `MyApp` isn't a class.”  
- **Cause:** The default Flutter test file still referenced `MyApp` after the main application widget had been renamed to `OversteerApp`.  
- **Fix:** Updated the test to reference `OversteerApp` or temporarily removed/commented out the default widget test until proper tests are written. This removed the analyzer error without impacting the running app.

---

## Issue 4 – Optional parameters in `_DriverResult` never used

- **Date:** 2025-12-05  
- **Area:** SessionPage / Results input (early version)  
- **Description:** Dart analyzer warning: “A value for optional parameter `gridPosition` isn't ever given” (and similarly for `finishPosition`) in the `_DriverResult` constructor.  
- **Cause:** `_DriverResult` defined `gridPosition` and `finishPosition` as optional constructor parameters, but instances were only created with `driverName`. The positions were set later from the text fields, so the constructor parameters were redundant.  
- **Fix:** Simplified `_DriverResult` so the constructor only required `driverName`, leaving `gridPosition` and `finishPosition` as nullable fields that were updated in `onChanged`. This cleared the warnings without changing runtime behaviour.  
- **Note:** This structure was later replaced entirely by the `SessionResult` model.

---

## Issue 5 – `driverRepository` named parameter errors during refactor

- **Date:** 2025-12-05  
- **Area:** Navigation / Dependency wiring  
- **Description:** Two related errors appeared during the introduction of the `DriverRepository`:
  - “The named parameter `driverRepository` isn't defined.”
  - “The named parameter `driverRepository` is required, but there's no corresponding argument.”  
- **Cause:** The refactor to add `DriverRepository` was partially applied:
  - Some widgets (e.g. `SessionPage`) required `driverRepository` in their constructors.
  - Parent widgets (`LeaguesPage`, `CompetitionsPage`, `DivisionPage`, and `main.dart`) were not all updated to define and pass the parameter consistently, and `leagues_page.dart` was initially missing the `driver_repository.dart` import.  
- **Fix:** Standardised the wiring:
  - Added `DriverRepository` creation in `main.dart` and passed it into `LeaguesPage`.
  - Updated `LeaguesPage`, `CompetitionsPage`, and `DivisionsPage` to accept a `DriverRepository` in their constructors and pass it down the navigation chain.
  - Updated `SessionPage` to require `driverRepository` and use it to load drivers.
  - Added `import '../repositories/driver_repository.dart';` where needed.  
  After these changes, all `driverRepository`-related errors were resolved.

---

## Issue 6 – Duplicate `league_page.dart` vs `leagues_page.dart`

- **Date:** 2025-12-06  
- **Area:** Screens / Navigation  
- **Description:** Analyzer error: “The named parameter `validationIssueRepository` is required, but there's no corresponding argument” in `league_page.dart`. At the same time, a separate `leagues_page.dart` existed and was used as the real home screen.  
- **Cause:** An older file `league_page.dart` (singular) remained in the project alongside the newer `leagues_page.dart` (plural). The old file had an outdated constructor and was no longer used by `main.dart`, but it still produced static analysis errors.  
- **Fix:** Removed `lib/screens/league_page.dart` entirely. The app now only uses `lib/screens/leagues_page.dart` as the entry screen, which matches the imports in `main.dart`. This eliminated the stray constructor error and reduced confusion.

---

## Issue 7 – `ValidationIssue` ID helper (`suffix_` / `_issueId`) warnings

- **Date:** 2025-12-06  
- **Area:** SessionPage / ValidationIssue generation  
- **Description:**
  - Analyzer error: “Undefined name `suffix_`.”
  - Lint warning: “The local variable `_issueId` starts with an underscore” (for a helper defined inside `_validateResults`).  
- **Cause:** While introducing `ValidationIssue` IDs, an intermediate implementation used a local helper function `_issueId(suffix_)`:
  - The parameter name `suffix_` was mis-typed in one place, causing the undefined identifier error.
  - The lint rule discouraged leading underscores for local identifiers.  
- **Fix:** Simplified the ID generation:
  - Removed the helper and generated `id` strings inline using string interpolation:
    - e.g. `'${event.id}_MISSING_GRID_${driver.id}_${timestamp}'`.
  - This removed both the undefined name error and the lint warning, and the code is now easier to read.

---

## Issue 8 – `validationIssueRepository` not passed through navigation

- **Date:** 2025-12-06  
- **Area:** Navigation / Dependency wiring  
- **Description:** Error: “The named parameter `validationIssueRepository` is required, but there's no corresponding argument” when building widgets such as `EventsPage` or `SessionPage`.  
- **Cause:** After adding `ValidationIssueRepository` to support the Issue Log, the constructor for several screens was updated, but the parent widgets were not initially passing the new dependency down the chain.  
- **Fix:** Standardised wiring for validation issues:
  - Created a single `ValidationIssueRepository` instance in `main.dart`.
  - Passed it into `LeaguesPage`, then through `CompetitionsPage`, `DivisionsPage`, and `EventsPage`.
  - Updated `SessionPage` and `IssueLogPage` to receive `validationIssueRepository` from their parents.  
  After these changes, all `validationIssueRepository` argument errors were resolved.

---

## Issue 9 – SessionPage validation ignored duplicate Grid positions

- **Date:** 2025-12-06  
- **Area:** SessionPage / Validation logic  
- **Description:** The initial validation logic correctly detected:
  - Missing grid/finish positions.
  - Duplicate **finish** positions.
  - Invalid finish ranges.  
  However, duplicate **grid** positions were not checked. Two drivers could share the same grid value (e.g. both set to 3) and the results would save without any issues raised.  
- **Cause:** `_validateResults()` only built a map for finish positions (`finishMap`). There was no equivalent map for grid positions, so duplicates on the grid were never detected.  
- **Fix:** Extended `_validateResults()`:
  - Added a `gridMap<int, List<Driver>>` to group drivers by `gridPosition`.
  - For any position with more than one driver, created a `ValidationIssue` with:
    - `code: 'DUPLICATE_GRID'`
    - Message: “Duplicate GRID position X for: Driver A, Driver B.”  
  - Now both duplicate Grid and duplicate Finish positions are logged and block saving.

---

---

## Issue 10 – Standings showed no data despite events existing

- **Date:** 2025-12-06  
- **Area:** StandingsPage / Data assumptions  
- **Description:** During initial testing of `StandingsPage`, some divisions showed “No classified results yet for this division” even though events existed in the calendar.  
- **Cause:** `StandingsPage` correctly only counts events that have **saved, validated** `SessionResult`s with a non-null `finishPosition`. Divisions with events but no saved session results (or only incomplete/invalid results that failed validation) legitimately produced an empty standings table.  
- **Fix / Decision:** No code change. This behaviour is intentional:
  - A division will only show standings once at least one event has valid, classified finish positions saved.
  - This was documented in the feature description so it is clear that “events existing” is not enough; **classified results** are required.

---

## Issue 11 – Consistency between Session summary and Standings

- **Date:** 2025-12-06  
- **Area:** SessionPage / StandingsPage  
- **Description:** Needed to ensure that what organisers see on the **“Current results (by finish)”** summary in `SessionPage` matches how `StandingsPage` interprets data when awarding points.  
- **Cause:** `SessionPage` shows all drivers with whatever grid/finish values are currently entered (including nulls), while `StandingsPage` only awards points for non-null `finishPosition` values. Without clarification, this could look like a mismatch.  
- **Fix / Decision:**  
  - Confirmed that `StandingsPage`:
    - Ignores drivers with `finishPosition == null` (unclassified / incomplete).
    - Ignores events where no valid results have been saved.
  - Left the logic as-is, but documented that:
    - The Session summary is a **live editing view**.
    - Standings only reflect **saved, fully validated** results.
