import 'package:flutter/material.dart';

import '../models/league.dart';
import '../models/competition.dart';
import '../models/division.dart';
import '../repositories/competition_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/session_result_repository.dart';
import '../repositories/validation_issue_repository.dart';
import 'events_page.dart';

class DivisionsPage extends StatefulWidget {
  final League league;
  final Competition competition;
  final CompetitionRepository competitionRepository;
  final EventRepository eventRepository;
  final DriverRepository driverRepository;
  final SessionResultRepository sessionResultRepository;
  final ValidationIssueRepository validationIssueRepository;

  const DivisionsPage({
    super.key,
    required this.league,
    required this.competition,
    required this.competitionRepository,
    required this.eventRepository,
    required this.driverRepository,
    required this.sessionResultRepository,
    required this.validationIssueRepository,
  });

  @override
  State<DivisionsPage> createState() => _DivisionsPageState();
}

class _DivisionsPageState extends State<DivisionsPage> {
  late Future<List<Division>> _futureDivisions;

  @override
  void initState() {
    super.initState();
    _futureDivisions = widget.competitionRepository
        .getDivisionsForCompetition(widget.competition.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Divisions – ${widget.competition.name}'),
      ),
      body: FutureBuilder<List<Division>>(
        future: _futureDivisions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading divisions: ${snapshot.error}'),
            );
          }

          final divisions = snapshot.data ?? [];

          if (divisions.isEmpty) {
            return const Center(
              child: Text('No divisions for this competition.'),
            );
          }

          return ListView.builder(
            itemCount: divisions.length,
            itemBuilder: (context, index) {
              final division = divisions[index];

              return ListTile(
                title: Text(division.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EventsPage(
                        league: widget.league,
                        competition: widget.competition,
                        division: division,
                        eventRepository: widget.eventRepository,
                        driverRepository: widget.driverRepository,
                        sessionResultRepository:
                            widget.sessionResultRepository,
                        validationIssueRepository:
                            widget.validationIssueRepository,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
