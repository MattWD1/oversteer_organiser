import 'package:flutter/material.dart';

import 'screens/leagues_page.dart';
import 'repositories/league_repository.dart';
import 'repositories/competition_repository.dart';
import 'repositories/event_repository.dart';
import 'repositories/driver_repository.dart';
import 'repositories/session_result_repository.dart';
import 'repositories/validation_issue_repository.dart';

void main() {
  // Create repositories once for the whole app
  final leagueRepository = InMemoryLeagueRepository();
  final competitionRepository = InMemoryCompetitionRepository();
  final eventRepository = InMemoryEventRepository();
  final driverRepository = InMemoryDriverRepository();
  final sessionResultRepository = SessionResultRepository();
  final validationIssueRepository = ValidationIssueRepository();

  runApp(
    OversteerApp(
      leagueRepository: leagueRepository,
      competitionRepository: competitionRepository,
      eventRepository: eventRepository,
      driverRepository: driverRepository,
      sessionResultRepository: sessionResultRepository,
      validationIssueRepository: validationIssueRepository,
    ),
  );
}

class OversteerApp extends StatelessWidget {
  final LeagueRepository leagueRepository;
  final CompetitionRepository competitionRepository;
  final EventRepository eventRepository;
  final DriverRepository driverRepository;
  final SessionResultRepository sessionResultRepository;
  final ValidationIssueRepository validationIssueRepository;

  const OversteerApp({
    super.key,
    required this.leagueRepository,
    required this.competitionRepository,
    required this.eventRepository,
    required this.driverRepository,
    required this.sessionResultRepository,
    required this.validationIssueRepository,
  });

  @override
  Widget build(BuildContext context) {
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
      ),
    );
  }
}
