// lib/screens/events_page.dart

import 'package:flutter/material.dart';

import '../models/league.dart';
import '../models/competition.dart';
import '../models/division.dart';
import '../models/event.dart';
import '../models/driver.dart';
import '../models/session_result.dart';
import '../models/penalty.dart';

import '../repositories/event_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/session_result_repository.dart';
import '../repositories/validation_issue_repository.dart';
import '../repositories/penalty_repository.dart';

import 'session_page.dart';
import 'issue_log_page.dart';
import 'penalties_page.dart';
import 'driver_profile_page.dart';

enum EventSortOption { name, date }

class EventsPage extends StatefulWidget {
  final League league;
  final Competition competition;
  final Division division;
  final EventRepository eventRepository;
  final DriverRepository driverRepository;
  final SessionResultRepository sessionResultRepository;
  final ValidationIssueRepository validationIssueRepository;
  final PenaltyRepository penaltyRepository;

  const EventsPage({
    super.key,
    required this.league,
    required this.competition,
    required this.division,
    required this.eventRepository,
    required this.driverRepository,
    required this.sessionResultRepository,
    required this.validationIssueRepository,
    required this.penaltyRepository,
  });

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late Future<List<Event>> _futureEvents;

  EventSortOption _sortOption = EventSortOption.date;
  int _currentTabIndex = 0; // 0 = Race, 1 = Teams, 2 = Drivers, 3 = Ranking

  @override
  void initState() {
    super.initState();
    _futureEvents =
        widget.eventRepository.getEventsForDivision(widget.division.id);
  }

  // Safely extract team name from Driver without assuming a field exists
  String _getTeamName(Driver driver) {
    try {
      final dynamic d = driver;
      final value = d.teamName;
      if (value is String && value.isNotEmpty) {
        return value;
      }
    } catch (_) {
      // ignore – driver just doesn't have a teamName field
    }
    return 'Unknown Team';
  }

  List<Event> _sortedEvents(List<Event> source) {
    final events = List<Event>.from(source);

    if (_sortOption == EventSortOption.name) {
      events.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    } else {
      events.sort((a, b) => a.date.compareTo(b.date));
    }

    return events;
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

  Future<List<Driver>> _loadDivisionDrivers() async {
    final events =
        await widget.eventRepository.getEventsForDivision(widget.division.id);
    final Map<String, Driver> driversById = {};

    for (final event in events) {
      final drivers = await widget.driverRepository.getDriversForEvent(event.id);
      for (final d in drivers) {
        driversById[d.id] = d;
      }
    }

    final driversList = driversById.values.toList();
    driversList.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return driversList;
  }

  Future<List<_TeamEntry>> _loadDivisionTeams() async {
    final drivers = await _loadDivisionDrivers();
    final Map<String, _TeamEntry> teams = {};

    for (final driver in drivers) {
      final teamName = _getTeamName(driver);
      final entry =
          teams.putIfAbsent(teamName, () => _TeamEntry(teamName: teamName));
      entry.driverCount += 1;
    }

    final list = teams.values.toList();
    list.sort((a, b) => a.teamName.compareTo(b.teamName));
    return list;
  }

  Future<_DivisionRankingData> _loadDivisionRanking() async {
    final events =
        await widget.eventRepository.getEventsForDivision(widget.division.id);

    if (events.isEmpty) {
      return const _DivisionRankingData(drivers: [], teams: []);
    }

    final Map<String, _DriverStanding> driverStandings = {};
    final Map<String, _TeamStanding> teamStandings = {};

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

      final List<_EventClassificationEntry> eventEntries = [];

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
          _EventClassificationEntry(
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

        final driverStanding = driverStandings.putIfAbsent(
          entry.driverId,
          () => _DriverStanding(
            driverId: entry.driverId,
            driverName: entry.driverName,
          ),
        );
        driverStanding.basePoints += basePoints;
        if (eventPos == 1) {
          driverStanding.wins += 1;
        }

        final teamStanding = teamStandings.putIfAbsent(
          entry.teamName,
          () => _TeamStanding(teamName: entry.teamName),
        );
        teamStanding.basePoints += basePoints;
        if (eventPos == 1) {
          teamStanding.wins += 1;
        }
      }

      pointsPenaltyByDriver.forEach((driverId, penaltyPoints) {
        final driver = driverById[driverId];
        final driverName = driver?.name ?? 'Unknown driver';

        final dStanding = driverStandings.putIfAbsent(
          driverId,
          () => _DriverStanding(driverId: driverId, driverName: driverName),
        );
        dStanding.penaltyPoints += penaltyPoints;

        final teamName =
            driver != null ? _getTeamName(driver) : 'Unknown Team';

        final tStanding = teamStandings.putIfAbsent(
          teamName,
          () => _TeamStanding(teamName: teamName),
        );
        tStanding.penaltyPoints += penaltyPoints;
      });
    }

    final driverList = driverStandings.values.toList();
    final teamList = teamStandings.values.toList();

    for (final d in driverList) {
      d.totalPoints = d.basePoints + d.penaltyPoints;
    }
    for (final t in teamList) {
      t.totalPoints = t.basePoints + t.penaltyPoints;
    }

    driverList.sort((a, b) {
      if (b.totalPoints != a.totalPoints) {
        return b.totalPoints.compareTo(a.totalPoints);
      }
      if (b.wins != a.wins) {
        return b.wins.compareTo(a.wins);
      }
      return a.driverName.compareTo(b.driverName);
    });

    teamList.sort((a, b) {
      if (b.totalPoints != a.totalPoints) {
        return b.totalPoints.compareTo(a.totalPoints);
      }
      if (b.wins != a.wins) {
        return b.wins.compareTo(a.wins);
      }
      return a.teamName.compareTo(b.teamName);
    });

    return _DivisionRankingData(drivers: driverList, teams: teamList);
  }

  // ---------- TABS ----------

  Widget _buildRaceTab() {
    return FutureBuilder<List<Event>>(
      future: _futureEvents,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading events: ${snapshot.error}'),
          );
        }

        final originalEvents = snapshot.data ?? [];

        if (originalEvents.isEmpty) {
          return const Center(
            child: Text('No events for this division.'),
          );
        }

        final events = _sortedEvents(originalEvents);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Sort by:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<EventSortOption>(
                    value: _sortOption,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: EventSortOption.name,
                        child: Text('Name'),
                      ),
                      DropdownMenuItem(
                        value: EventSortOption.date,
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
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];

                  return ListTile(
                    title: Text(event.name),
                    subtitle: Text('${event.date.toLocal()}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Penalties',
                          icon: const Icon(Icons.gavel_outlined),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PenaltiesPage(
                                  event: event,
                                  driverRepository: widget.driverRepository,
                                  penaltyRepository:
                                      widget.penaltyRepository,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          tooltip: 'View validation issues',
                          icon:
                              const Icon(Icons.warning_amber_outlined),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => IssueLogPage(
                                  event: event,
                                  validationIssueRepository:
                                      widget.validationIssueRepository,
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
                          builder: (_) => SessionPage(
                            event: event,
                            driverRepository: widget.driverRepository,
                            sessionResultRepository:
                                widget.sessionResultRepository,
                            validationIssueRepository:
                                widget.validationIssueRepository,
                            penaltyRepository:
                                widget.penaltyRepository,
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
    );
  }

  Widget _buildTeamsTab() {
    return FutureBuilder<List<_TeamEntry>>(
      future: _loadDivisionTeams(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading teams: ${snapshot.error}'),
          );
        }

        final teams = snapshot.data ?? [];

        if (teams.isEmpty) {
          return const Center(
            child: Text('No teams found for this division.'),
          );
        }

        return ListView.builder(
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index];
            return ListTile(
              leading: const Icon(Icons.groups),
              title: Text(team.teamName),
              subtitle: Text('Drivers: ${team.driverCount}'),
            );
          },
        );
      },
    );
  }

  Widget _buildDriversTab() {
    return FutureBuilder<List<Driver>>(
      future: _loadDivisionDrivers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading drivers: ${snapshot.error}'),
          );
        }

        final drivers = snapshot.data ?? [];

        if (drivers.isEmpty) {
          return const Center(
            child: Text('No drivers found for this division.'),
          );
        }

        return ListView.builder(
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            final driver = drivers[index];
            final teamName = _getTeamName(driver);

            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(driver.name),
              subtitle: Text('Team: $teamName'),
              onTap: () {
                // Open driver profile from Drivers tab
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DriverProfilePage(
                      driver: driver,
                      division: widget.division,
                      eventRepository: widget.eventRepository,
                      sessionResultRepository:
                          widget.sessionResultRepository,
                      penaltyRepository: widget.penaltyRepository,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRankingTab() {
    return FutureBuilder<_DivisionRankingData>(
      future: _loadDivisionRanking(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading rankings: ${snapshot.error}'),
          );
        }

        final data = snapshot.data ??
            const _DivisionRankingData(drivers: [], teams: []);

        if (data.drivers.isEmpty && data.teams.isEmpty) {
          return const Center(
            child: Text('No classified results yet for this division.'),
          );
        }

        return ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Drivers\' Championship',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...data.drivers.asMap().entries.map((entry) {
              final index = entry.key;
              final standing = entry.value;
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
                title: Text(standing.driverName),
                subtitle: Text(subtitle),
                onTap: () {
                  // Open driver profile when tapping a driver in standings
                  final driver = Driver(
                    id: standing.driverId,
                    name: standing.driverName,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DriverProfilePage(
                        driver: driver,
                        division: widget.division,
                        eventRepository: widget.eventRepository,
                        sessionResultRepository:
                            widget.sessionResultRepository,
                        penaltyRepository: widget.penaltyRepository,
                      ),
                    ),
                  );
                },
              );
            }),
            const Divider(height: 32),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Constructors\' Championship',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...data.teams.asMap().entries.map((entry) {
              final index = entry.key;
              final standing = entry.value;
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
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_currentTabIndex) {
      case 0:
        body = _buildRaceTab();
        break;
      case 1:
        body = _buildTeamsTab();
        break;
      case 2:
        body = _buildDriversTab();
        break;
      case 3:
      default:
        body = _buildRankingTab();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.division.name),
      ),
      body: body,
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
            icon: Icon(Icons.flag),
            label: 'Race',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Teams',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Drivers',
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

// --------- helper classes ---------

class _TeamEntry {
  final String teamName;
  int driverCount;

  _TeamEntry({
    required this.teamName,
  }) : driverCount = 0;
}

class _DriverStanding {
  final String driverId;
  final String driverName;
  int basePoints;
  int penaltyPoints;
  int totalPoints;
  int wins;

  _DriverStanding({
    required this.driverId,
    required this.driverName,
  })  : basePoints = 0,
        penaltyPoints = 0,
        totalPoints = 0,
        wins = 0;
}

class _TeamStanding {
  final String teamName;
  int basePoints;
  int penaltyPoints;
  int totalPoints;
  int wins;

  _TeamStanding({
    required this.teamName,
  })  : basePoints = 0,
        penaltyPoints = 0,
        totalPoints = 0,
        wins = 0;
}

class _EventClassificationEntry {
  final String driverId;
  final String driverName;
  final String teamName;
  final int baseTimeMs;
  final int adjustedTimeMs;

  _EventClassificationEntry({
    required this.driverId,
    required this.driverName,
    required this.teamName,
    required this.baseTimeMs,
    required this.adjustedTimeMs,
  });
}

class _DivisionRankingData {
  final List<_DriverStanding> drivers;
  final List<_TeamStanding> teams;

  const _DivisionRankingData({
    required this.drivers,
    required this.teams,
  });
}
