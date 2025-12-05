import 'package:flutter/material.dart';
import 'screens/leagues_page.dart';
import 'repositories/league_repository.dart';
import 'repositories/competition_repository.dart';
import 'repositories/event_repository.dart';
import 'repositories/driver_repository.dart';

void main() {
  runApp(const OversteerApp());
}

class OversteerApp extends StatelessWidget {
  const OversteerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final leagueRepository = InMemoryLeagueRepository();
    final competitionRepository = InMemoryCompetitionRepository();
    final eventRepository = InMemoryEventRepository();
    final driverRepository = InMemoryDriverRepository();

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
      ),
    );
  }
}
