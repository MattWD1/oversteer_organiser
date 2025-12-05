# Feature: My Leagues screen

## Purpose
- Show leagues available to the current user.
- First step into the league → division → race navigation flow.

## Key Files
- `lib/models/league.dart`
- `lib/repositories/league_repository.dart`
- `lib/screens/leagues_page.dart`
- `lib/main.dart`

## What I Implemented
- League model with id, name, organiserName, code.
- In-memory LeagueRepository returning dummy leagues.
- LeaguesPage that loads leagues with a loading spinner and displays them in a ListView.

## Problems Hit
- Import error for `leagues_page.dart` when file didn’t exist (see Issue 2 in issues-log).

## Next TODOs
- Add “Create League” flow.
- Swap in-memory repo for real database/API later.
