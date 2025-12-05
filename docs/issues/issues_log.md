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
