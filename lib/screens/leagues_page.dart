import 'package:flutter/material.dart';

import '../models/league.dart';
import '../repositories/league_repository.dart';
import '../repositories/competition_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/session_result_repository.dart';
import '../repositories/validation_issue_repository.dart';
import '../repositories/penalty_repository.dart';
import 'divisions_page.dart';

class LeaguesPage extends StatefulWidget {
  final LeagueRepository repository;
  final CompetitionRepository competitionRepository;
  final EventRepository eventRepository;
  final DriverRepository driverRepository;
  final SessionResultRepository sessionResultRepository;
  final ValidationIssueRepository validationIssueRepository;
  final PenaltyRepository penaltyRepository;

  const LeaguesPage({
    super.key,
    required this.repository,
    required this.competitionRepository,
    required this.eventRepository,
    required this.driverRepository,
    required this.sessionResultRepository,
    required this.validationIssueRepository,
    required this.penaltyRepository,
  });

  @override
  State<LeaguesPage> createState() => _LeaguesPageState();
}

class _LeaguesPageState extends State<LeaguesPage> {
  late Future<List<League>> _futureLeagues;

  @override
  void initState() {
    super.initState();
    _futureLeagues = widget.repository.getLeaguesForCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Leagues'),
      ),
      body: FutureBuilder<List<League>>(
        future: _futureLeagues,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading leagues: ${snapshot.error}'),
            );
          }

          final leagues = snapshot.data ?? [];

          if (leagues.isEmpty) {
            return const Center(
              child: Text('No leagues yet.'),
            );
          }

          return ListView.builder(
            itemCount: leagues.length,
            itemBuilder: (context, index) {
              final league = leagues[index];

              return ListTile(
                title: Text(league.name),
                subtitle: Text('Organiser: ${league.organiserName}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  try {
                    final competitions = await widget.competitionRepository
                        .getCompetitionsForLeague(league.id);

                    if (!mounted) return;

                    if (competitions.isEmpty) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No seasons set up for this league yet.',
                          ),
                        ),
                      );
                      return;
                    }

                    final currentCompetition = competitions.first;

                    // ignore: use_build_context_synchronously
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DivisionsPage(
                          league: league,
                          competition: currentCompetition,
                          competitionRepository:
                              widget.competitionRepository,
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
                  } catch (e) {
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Error loading divisions for league: $e'),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
