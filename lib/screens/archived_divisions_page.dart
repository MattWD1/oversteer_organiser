import 'package:flutter/material.dart';

import '../models/league.dart';
import '../models/division.dart';
import '../models/competition.dart';

import '../repositories/competition_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/session_result_repository.dart';
import '../repositories/validation_issue_repository.dart';
import '../repositories/penalty_repository.dart';

import 'events_page.dart';
import 'standings_page.dart';

class ArchivedDivisionsPage extends StatefulWidget {
  final League league;
  final CompetitionRepository competitionRepository;
  final EventRepository eventRepository;
  final DriverRepository driverRepository;
  final SessionResultRepository sessionResultRepository;
  final ValidationIssueRepository validationIssueRepository;
  final PenaltyRepository penaltyRepository;

  const ArchivedDivisionsPage({
    super.key,
    required this.league,
    required this.competitionRepository,
    required this.eventRepository,
    required this.driverRepository,
    required this.sessionResultRepository,
    required this.validationIssueRepository,
    required this.penaltyRepository,
  });

  @override
  State<ArchivedDivisionsPage> createState() => _ArchivedDivisionsPageState();
}

class _ArchivedDivisionsPageState extends State<ArchivedDivisionsPage> {
  late Future<List<Division>> _futureArchivedDivisions;

  @override
  void initState() {
    super.initState();
    _futureArchivedDivisions = widget.competitionRepository
        .getArchivedDivisionsForLeague(widget.league.id);
  }

  Future<Competition?> _loadCompetitionFor(Division division) {
    return widget.competitionRepository
        .getCompetitionForDivision(division.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Archive – ${widget.league.name}'),
      ),
      body: FutureBuilder<List<Division>>(
        future: _futureArchivedDivisions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child:
                  Text('Error loading archived divisions: ${snapshot.error}'),
            );
          }

          final divisions = snapshot.data ?? [];

          if (divisions.isEmpty) {
            return const Center(
              child: Text('No archived divisions for this league yet.'),
            );
          }

          return ListView.builder(
            itemCount: divisions.length,
            itemBuilder: (context, index) {
              final division = divisions[index];

              return ListTile(
                title: Text(division.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'View standings',
                      icon: const Icon(Icons.emoji_events_outlined),
                      onPressed: () async {
                        final competition =
                            await _loadCompetitionFor(division);
                        if (!mounted) return;
                        if (competition == null) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Could not find the season for this division.'),
                            ),
                          );
                          return;
                        }

                        // ignore: use_build_context_synchronously
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StandingsPage(
                              league: widget.league,
                              competition: competition,
                              division: division,
                              eventRepository: widget.eventRepository,
                              driverRepository: widget.driverRepository,
                              sessionResultRepository:
                                  widget.sessionResultRepository,
                              penaltyRepository:
                                  widget.penaltyRepository,
                            ),
                          ),
                        );
                      },
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () async {
                  final competition = await _loadCompetitionFor(division);
                  if (!mounted) return;
                  if (competition == null) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Could not find the season for this division.'),
                      ),
                    );
                    return;
                  }

                  // ignore: use_build_context_synchronously
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EventsPage(
                        league: widget.league,
                        competition: competition,
                        division: division,
                        competitionRepository: widget.competitionRepository,
                        eventRepository: widget.eventRepository,
                        driverRepository: widget.driverRepository,
                        sessionResultRepository:
                            widget.sessionResultRepository,
                        validationIssueRepository:
                            widget.validationIssueRepository,
                        penaltyRepository: widget.penaltyRepository,
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
