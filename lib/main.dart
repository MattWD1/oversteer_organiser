import 'package:flutter/material.dart';

import 'screens/leagues_page.dart';
import 'repositories/league_repository.dart';
import 'repositories/competition_repository.dart';
import 'repositories/event_repository.dart';
import 'repositories/driver_repository.dart';
import 'repositories/session_result_repository.dart';
import 'repositories/validation_issue_repository.dart';
import 'repositories/penalty_repository.dart';

void main() {
  runApp(const OversteerApp());
}

class OversteerApp extends StatelessWidget {
  const OversteerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Core repositories
    final leagueRepository = InMemoryLeagueRepository();
    final competitionRepository = InMemoryCompetitionRepository();
    final eventRepository = InMemoryEventRepository();
    final driverRepository = InMemoryDriverRepository();

    // These are simple concrete classes in your project
    final sessionResultRepository = SessionResultRepository();
    final validationIssueRepository = ValidationIssueRepository();

    // Penalties use an in-memory implementation
    final penaltyRepository = InMemoryPenaltyRepository();

    return MaterialApp(
      title: 'Oversteer Organiser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: LeaguesPage(
        repository: leagueRepository,
        competitionRepository: competitionRepository,
        eventRepository: eventRepository,
        driverRepository: driverRepository,
        sessionResultRepository: sessionResultRepository,
        validationIssueRepository: validationIssueRepository,
        penaltyRepository: penaltyRepository,
      ),
    );
  }
}
