import 'package:flutter/material.dart';

import '../models/league.dart';
import '../repositories/league_repository.dart';
import '../repositories/competition_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/session_result_repository.dart';
import '../repositories/validation_issue_repository.dart';
import '../repositories/penalty_repository.dart';
import 'competitions_page.dart';

enum LeagueSortOption { name, date }

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
  LeagueSortOption _sortOption = LeagueSortOption.name;

  @override
  void initState() {
    super.initState();
    _futureLeagues = widget.repository.getLeaguesForCurrentUser();
  }

  List<League> _sortedLeagues(List<League> source) {
    // Clone the list so we never mutate the original snapshot list
    final leagues = List<League>.from(source);

    if (_sortOption == LeagueSortOption.name) {
      leagues.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    } else {
      // Sort by "Date" currently means: keep repository order.
      // When a real date field is added to League, hook it up here.
    }

    return leagues;
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

          final originalLeagues = snapshot.data ?? [];

          if (originalLeagues.isEmpty) {
            return const Center(
              child: Text('No leagues yet.'),
            );
          }

          final leagues = _sortedLeagues(originalLeagues);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Sort row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Leagues',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text(
                          'Sort by:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<LeagueSortOption>(
                          value: _sortOption,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: LeagueSortOption.name,
                              child: Text('Name'),
                            ),
                            DropdownMenuItem(
                              value: LeagueSortOption.date,
                              child: Text('Date'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _sortOption = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: leagues.length,
                  itemBuilder: (context, index) {
                    final league = leagues[index];

                    return ListTile(
                      title: Text(league.name),
                      subtitle: Text('Organiser: ${league.organiserName}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CompetitionsPage(
                              league: league,
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
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
