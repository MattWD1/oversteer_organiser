# Issues Log

---

## Issue 1 – Flutter screen stuck on phone

- **Date:** 2025-12-05  
- **Area:** Setup / First Run  
- **Description:** AI-generated scrap project ran but only showed the Flutter splash screen and then appeared stuck.  
- **Cause:** The generated code was broken / incomplete, not a problem with the Flutter or device setup.  
- **Fix:** Created a clean Flutter project and replaced `main.dart` with a simple test app. Confirmed the test page runs on the phone.

---

## Issue 2 – `leagues_page.dart` import error

- **Date:** 2025-12-05  
- **Area:** Project structure / VS Code  
- **Description:** Error: “Target of URI doesn't exist: `screens/leagues_page.dart`” and “The method `LeaguesPage` isn't defined”.  
- **Cause:** `main.dart` imported `screens/leagues_page.dart` and used `LeaguesPage`, but the file hadn’t been created under `lib/screens`.  
- **Fix:** Created `lib/screens/leagues_page.dart` with the `LeaguesPage` widget and saved all files. Import and class resolved correctly.

---

## Issue 3 – `MyApp` not found in `widget_test.dart`

- **Date:** 2025-12-05  
- **Area:** Testing / Default Flutter test  
- **Description:** Error: “The name `MyApp` isn't a class” in `test/widget_test.dart`.  
- **Cause:** Default Flutter test still referenced `MyApp` after the main app widget was renamed to `OversteerApp`.  
- **Fix:** Updated the test to use `OversteerApp` or commented out / removed the default test file until tests are needed.

---
---

## Issue 4 – Optional parameters not used in SessionPage

- **Date:** 2025-12-05  
- **Area:** SessionPage / results input screen  
- **Description:** Dart analyzer warning: “A value for optional parameter 'gridPosition' isn't ever given” and the same for 'finishPosition'.  
- **Cause:** `_DriverResult` constructor defined optional parameters `gridPosition` and `finishPosition`, but these values are never passed in when creating `_DriverResult` instances. They are only set later via `onChanged` in the text fields.  
- **Fix:** Simplified `_DriverResult` so the constructor only requires `driverName`, keeping `gridPosition` and `finishPosition` as fields that are updated after the user types. This cleared the analyzer warnings without changing behaviour.
