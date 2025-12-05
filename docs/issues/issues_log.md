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
- **Area:** SessionPage / Results input  
- **Description:** Dart analyzer warning: “A value for optional parameter `gridPosition` isn't ever given” (and similarly for `finishPosition`) in the `_DriverResult` constructor.  
- **Cause:** `_DriverResult` defined `gridPosition` and `finishPosition` as optional constructor parameters, but instances were only created with `driverName`. The positions were set later from the text fields, so the constructor parameters were redundant.  
- **Fix:** Simplified `_DriverResult` so the constructor only requires `driverName`, leaving `gridPosition` and `finishPosition` as nullable fields that are updated in `onChanged`. This cleared the warnings without changing runtime behaviour.

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
  - Updated `LeaguesPage`, `CompetitionsPage`, and `DivisionPage` to accept a `DriverRepository` in their constructors and pass it down the navigation chain.
  - Updated `SessionPage` to require `driverRepository` and use it to load drivers.
  - Added `import '../repositories/driver_repository.dart';` where needed.  
  After these changes, all `driverRepository`-related errors were resolved.

---
