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

enum LeagueSortOption {
  nameAsc,
  nameDesc,
  dateCreatedNewest,
}

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
  LeagueSortOption _sortOption = LeagueSortOption.nameAsc;

  @override
  void initState() {
    super.initState();
    _futureLeagues = widget.repository.getLeaguesForCurrentUser();
  }

  String _sortLabel(LeagueSortOption option) {
    switch (option) {
      case LeagueSortOption.nameAsc:
        return 'Name (A–Z)';
      case LeagueSortOption.nameDesc:
        return 'Name (Z–A)';
      case LeagueSortOption.dateCreatedNewest:
        return 'Date Created (Newest)';
    }
  }

  List<League> _sortedLeagues(List<League> source) {
    final leagues = List<League>.from(source);

    leagues.sort((a, b) {
      switch (_sortOption) {
        case LeagueSortOption.nameAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case LeagueSortOption.nameDesc:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case LeagueSortOption.dateCreatedNewest:
          // Newest first = later createdAt comes first
          return b.createdAt.compareTo(a.createdAt);
      }
    });

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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sort by',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    PopupMenuButton<LeagueSortOption>(
                      initialValue: _sortOption,
                      onSelected: (value) {
                        setState(() {
                          _sortOption = value;
                        });
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: LeagueSortOption.nameAsc,
                          child: Text('Name (A–Z)'),
                        ),
                        PopupMenuItem(
                          value: LeagueSortOption.nameDesc,
                          child: Text('Name (Z–A)'),
                        ),
                        PopupMenuItem(
                          value: LeagueSortOption.dateCreatedNewest,
                          child: Text('Date Created (Newest)'),
                        ),
                      ],
                      child: Row(
                        children: [
                          Text(
                            _sortLabel(_sortOption),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
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
                            builder: (_) => DivisionsPage(
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
