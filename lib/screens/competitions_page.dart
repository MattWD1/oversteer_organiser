import 'package:flutter/material.dart';

import '../models/league.dart';
import '../models/competition.dart';
import '../repositories/competition_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/session_result_repository.dart';
import '../repositories/validation_issue_repository.dart';
import 'divisions_page.dart';

class CompetitionsPage extends StatefulWidget {
  final League league;
  final CompetitionRepository competitionRepository;
  final EventRepository eventRepository;
  final DriverRepository driverRepository;
  final SessionResultRepository sessionResultRepository;
  final ValidationIssueRepository validationIssueRepository;

  const CompetitionsPage({
    super.key,
    required this.league,
    required this.competitionRepository,
    required this.eventRepository,
    required this.driverRepository,
    required this.sessionResultRepository,
    required this.validationIssueRepository,
  });

  @override
  State<CompetitionsPage> createState() => _CompetitionsPageState();
}

class _CompetitionsPageState extends State<CompetitionsPage> {
  late Future<List<Competition>> _futureCompetitions;

  @override
  void initState() {
    super.initState();
    _futureCompetitions = widget.competitionRepository
        .getCompetitionsForLeague(widget.league.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Competitions – ${widget.league.name}'),
      ),
      body: FutureBuilder<List<Competition>>(
        future: _futureCompetitions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading competitions: ${snapshot.error}'),
            );
          }

          final competitions = snapshot.data ?? [];

          if (competitions.isEmpty) {
            return const Center(
              child: Text('No competitions found for this league.'),
            );
          }

          return ListView.builder(
            itemCount: competitions.length,
            itemBuilder: (context, index) {
              final competition = competitions[index];

              return ListTile(
                title: Text(competition.name),
                subtitle: Text('Season: ${competition.seasonName ?? 'N/A'}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DivisionsPage(
                        league: widget.league,
                        competition: competition,
                        competitionRepository: widget.competitionRepository,
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
