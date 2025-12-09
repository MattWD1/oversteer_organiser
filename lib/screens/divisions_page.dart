import 'package:flutter/material.dart';

import '../models/league.dart';
import '../models/competition.dart';
import '../models/division.dart';
import '../models/event.dart';
import '../models/driver.dart';
import '../models/session_result.dart';
import '../models/penalty.dart';

import '../repositories/competition_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/session_result_repository.dart';
import '../repositories/validation_issue_repository.dart';
import '../repositories/penalty_repository.dart';

import 'events_page.dart';
import 'standings_page.dart';
import 'archived_divisions_page.dart';

class DivisionsPage extends StatefulWidget {
  final League league;
  final Competition competition;
  final CompetitionRepository competitionRepository;
  final EventRepository eventRepository;
  final DriverRepository driverRepository;
  final SessionResultRepository sessionResultRepository;
  final ValidationIssueRepository validationIssueRepository;
  final PenaltyRepository penaltyRepository;

  const DivisionsPage({
    super.key,
    required this.league,
    required this.competition,
    required this.competitionRepository,
    required this.eventRepository,
    required this.driverRepository,
    required this.sessionResultRepository,
    required this.validationIssueRepository,
    required this.penaltyRepository,
  });

  @override
  State<DivisionsPage> createState() => _DivisionsPageState();
}

class _DivisionsPageState extends State<DivisionsPage> {
  late Future<List<Division>> _futureDivisions;

  // 0 = Divisions list, 1 = Overall Constructors Ranking
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _futureDivisions = widget.competitionRepository
        .getDivisionsForCompetition(widget.competition.id);
  }

  Future<void> _reloadDivisions() async {
    setState(() {
      _futureDivisions = widget.competitionRepository
          .getDivisionsForCompetition(widget.competition.id);
    });
  }

  Future<void> _archiveDivision(Division division) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive division'),
        content: Text(
          'Archive "${division.name}"?\n\n'
          'It will be moved to the archive for this league and '
          'removed from the active divisions list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await widget.competitionRepository
        .archiveDivision(widget.league.id, division.id);

    if (!mounted) return;
    await _reloadDivisions();
  }

  // ---- Helpers for Overall Constructors Ranking ----

  String _getTeamName(Driver driver) {
    try {
      final dynamic d = driver;
      final value = d.teamName;
      if (value is String && value.isNotEmpty) {
        return value;
      }
    } catch (_) {
      // Driver has no teamName field.
    }
    return 'Unknown Team';
  }

  int _pointsForFinish(int position) {
    switch (position) {
      case 1:
        return 25;
      case 2:
        return 18;
      case 3:
        return 15;
      case 4:
        return 12;
      case 5:
        return 10;
      case 6:
        return 8;
      case 7:
        return 6;
      case 8:
        return 4;
      case 9:
        return 2;
      case 10:
        return 1;
      default:
        return 0;
    }
  }

  /// Overall Constructors Championship for the whole league.
  Future<List<_LeagueTeamStanding>> _computeLeagueConstructors() async {
    try {
      final competitions = await widget.competitionRepository
          .getCompetitionsForLeague(widget.league.id);

      if (competitions.isEmpty) {
        return [];
      }

      final Map<String, _LeagueTeamStanding> standingsMap = {};

      for (final competition in competitions) {
        final List<Division> divisions =
            await widget.competitionRepository.getDivisionsForCompetition(
          competition.id,
        );

        for (final division in divisions) {
          final List<Event> events =
              await widget.eventRepository.getEventsForDivision(division.id);

          for (final event in events) {
            final List<SessionResult> results =
                widget.sessionResultRepository.getResultsForEvent(event.id);

            if (results.isEmpty) {
              continue;
            }

            final List<Driver> eventDrivers =
                await widget.driverRepository.getDriversForEvent(event.id);

            final Map<String, Driver> driverById = {
              for (final d in eventDrivers) d.id: d,
            };

            final List<Penalty> eventPenalties =
                widget.penaltyRepository.getPenaltiesForEvent(event.id);

            final Map<String, int> timePenaltySecondsByDriver = {};
            final Map<String, int> pointsPenaltyByDriver = {};

            for (final p in eventPenalties) {
              if (p.type == 'Time') {
                timePenaltySecondsByDriver[p.driverId] =
                    (timePenaltySecondsByDriver[p.driverId] ?? 0) + p.value;
              } else if (p.type == 'Points') {
                pointsPenaltyByDriver[p.driverId] =
                    (pointsPenaltyByDriver[p.driverId] ?? 0) + p.value;
              }
            }

            final List<_LeagueEventClassificationEntry> eventEntries = [];

            for (final result in results) {
              final baseTimeMs = result.raceTimeMillis;
              if (baseTimeMs == null) {
                continue;
              }

              final driverId = result.driverId;
              final driver = driverById[driverId];

              final teamName =
                  driver != null ? _getTeamName(driver) : 'Unknown Team';

              final timePenSec = timePenaltySecondsByDriver[driverId] ?? 0;
              final adjustedTimeMs = baseTimeMs + timePenSec * 1000;

              eventEntries.add(
                _LeagueEventClassificationEntry(
                  driverId: driverId,
                  driverName: driver?.name ?? 'Unknown driver',
                  teamName: teamName,
                  baseTimeMs: baseTimeMs,
                  adjustedTimeMs: adjustedTimeMs,
                ),
              );
            }

            if (eventEntries.isEmpty) {
              continue;
            }

            eventEntries.sort(
              (a, b) => a.adjustedTimeMs.compareTo(b.adjustedTimeMs),
            );

            for (var index = 0; index < eventEntries.length; index++) {
              final entry = eventEntries[index];
              final eventPos = index + 1;
              final basePoints = _pointsForFinish(eventPos);

              final standing = standingsMap.putIfAbsent(
                entry.teamName,
                () => _LeagueTeamStanding(teamName: entry.teamName),
              );

              standing.basePoints += basePoints;
              if (eventPos == 1) {
                standing.wins += 1;
              }
            }

            pointsPenaltyByDriver.forEach((driverId, penaltyPoints) {
              final driver = driverById[driverId];

              final teamName =
                  driver != null ? _getTeamName(driver) : 'Unknown Team';

              final standing = standingsMap.putIfAbsent(
                teamName,
                () => _LeagueTeamStanding(teamName: teamName),
              );

              standing.penaltyPoints += penaltyPoints;
            });
          }
        }
      }

      final standingsList = standingsMap.values.toList();

      for (final s in standingsList) {
        s.totalPoints = s.basePoints + s.penaltyPoints;
      }

      standingsList.sort((a, b) {
        if (b.totalPoints != a.totalPoints) {
          return b.totalPoints.compareTo(a.totalPoints);
        }
        if (b.wins != a.wins) {
          return b.wins.compareTo(a.wins);
        }
        return a.teamName.compareTo(b.teamName);
      });

      return standingsList;
    } catch (e) {
      throw Exception('Error loading overall constructors: $e');
    }
  }

  // ---- UI builders ----

  Widget _buildDivisionsTab() {
    return FutureBuilder<List<Division>>(
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
            child: Text('No active divisions for this season.'),
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
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StandingsPage(
                            league: widget.league,
                            competition: widget.competition,
                            division: division,
                            eventRepository: widget.eventRepository,
                            driverRepository: widget.driverRepository,
                            sessionResultRepository:
                                widget.sessionResultRepository,
                            penaltyRepository: widget.penaltyRepository,
                          ),
                        ),
                      );
                    },
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
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
                      penaltyRepository: widget.penaltyRepository,
                    ),
                  ),
                );
              },
              onLongPress: () => _archiveDivision(division),
            );
          },
        );
      },
    );
  }

  Widget _buildRankingTab() {
    return FutureBuilder<List<_LeagueTeamStanding>>(
      future: _computeLeagueConstructors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading ranking: ${snapshot.error}'),
          );
        }

        final standings = snapshot.data ?? [];

        if (standings.isEmpty) {
          return const Center(
            child: Text('No classified results yet for this league.'),
          );
        }

        return ListView.builder(
          itemCount: standings.length,
          itemBuilder: (context, index) {
            final standing = standings[index];
            final position = index + 1;

            final base = standing.basePoints;
            final pen = standing.penaltyPoints;
            final total = standing.totalPoints;

            final subtitle =
                'Points: $total (Base $base, Penalties $pen) • Wins: ${standing.wins}';

            return ListTile(
              leading: CircleAvatar(
                child: Text(position.toString()),
              ),
              title: Text(standing.teamName),
              subtitle: Text(subtitle),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Divisions – ${widget.league.name}'),
        actions: [
          IconButton(
            tooltip: 'View archive',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ArchivedDivisionsPage(
                    league: widget.league,
                    competitionRepository: widget.competitionRepository,
                    eventRepository: widget.eventRepository,
                    driverRepository: widget.driverRepository,
                    sessionResultRepository: widget.sessionResultRepository,
                    validationIssueRepository:
                        widget.validationIssueRepository,
                    penaltyRepository: widget.penaltyRepository,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body:
          _currentTabIndex == 0 ? _buildDivisionsTab() : _buildRankingTab(),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list),
            label: 'Divisions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            label: 'Ranking',
          ),
        ],
      ),
    );
  }
}

// ---- Private models for league constructors ranking ----

class _LeagueTeamStanding {
  final String teamName;
  int basePoints;
  int penaltyPoints;
  int totalPoints;
  int wins;

  _LeagueTeamStanding({
    required this.teamName,
  })  : basePoints = 0,
        penaltyPoints = 0,
        totalPoints = 0,
        wins = 0;
}

class _LeagueEventClassificationEntry {
  final String driverId;
  final String driverName;
  final String teamName;
  final int baseTimeMs;
  final int adjustedTimeMs;

  _LeagueEventClassificationEntry({
    required this.driverId,
    required this.driverName,
    required this.teamName,
    required this.baseTimeMs,
    required this.adjustedTimeMs,
  });
}
