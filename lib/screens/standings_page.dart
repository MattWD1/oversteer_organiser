// lib/screens/standings_page.dart

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
import '../repositories/penalty_repository.dart';

class StandingsPage extends StatefulWidget {
  final League league;
  final Competition competition;
  final Division division;
  final EventRepository eventRepository;
  final DriverRepository driverRepository;
  final SessionResultRepository sessionResultRepository;
  final PenaltyRepository penaltyRepository;

  const StandingsPage({
    super.key,
    required this.league,
    required this.competition,
    required this.division,
    required this.eventRepository,
    required this.driverRepository,
    required this.sessionResultRepository,
    required this.penaltyRepository,
  });

  @override
  State<StandingsPage> createState() => _StandingsPageState();
}

class _StandingsPageState extends State<StandingsPage> {
  bool _isLoading = true;
  String? _error;

  List<_DriverStanding> _standings = [];

  @override
  void initState() {
    super.initState();
    _loadStandings();
  }

  Future<void> _loadStandings() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _standings = [];
    });

    try {
      final List<Event> events =
          await widget.eventRepository.getEventsForDivision(widget.division.id);

      if (events.isEmpty) {
        setState(() {
          _isLoading = false;
          _standings = [];
        });
        return;
      }

      final Map<String, _DriverStanding> standingsMap = {};

      // --------- PART A: Base points from adjusted race results ---------
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

        // Time & points penalties for this event
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

        // Build per-event adjusted times
        final List<_EventClassificationEntry> eventEntries = [];

        for (final result in results) {
          final baseTimeMs = result.raceTimeMillis;
          if (baseTimeMs == null) {
            // No race time, cannot classify fairly
            continue;
          }

          final driverId = result.driverId;
          final driver = driverById[driverId];
          final driverName = driver?.name ?? 'Unknown driver';

          final timePenSec = timePenaltySecondsByDriver[driverId] ?? 0;
          final adjustedTimeMs = baseTimeMs + timePenSec * 1000;

          eventEntries.add(
            _EventClassificationEntry(
              driverId: driverId,
              driverName: driverName,
              baseTimeMs: baseTimeMs,
              adjustedTimeMs: adjustedTimeMs,
            ),
          );
        }

        if (eventEntries.isEmpty) {
          continue;
        }

        // Sort event entries by adjusted time ascending
        eventEntries.sort(
          (a, b) => a.adjustedTimeMs.compareTo(b.adjustedTimeMs),
        );

        // Assign final event positions based on adjusted times
        for (var index = 0; index < eventEntries.length; index++) {
          final entry = eventEntries[index];
          final eventPos = index + 1;
          final basePoints = _pointsForFinish(eventPos);

          final standing = standingsMap.putIfAbsent(
            entry.driverId,
            () => _DriverStanding(
              driverId: entry.driverId,
              driverName: entry.driverName,
            ),
          );

          standing.basePoints += basePoints;
          if (eventPos == 1) {
            standing.wins += 1;
          }
        }

        // Apply any points penalties for this event
        pointsPenaltyByDriver.forEach((driverId, penaltyPoints) {
          final driverName = driverById[driverId]?.name ?? 'Unknown driver';
          final standing = standingsMap.putIfAbsent(
            driverId,
            () => _DriverStanding(
              driverId: driverId,
              driverName: driverName,
            ),
          );
          standing.penaltyPoints += penaltyPoints; // typically negative
        });
      }

      final standingsList = standingsMap.values.toList();

      // Compute final totals
      for (final s in standingsList) {
        s.totalPoints = s.basePoints + s.penaltyPoints;
      }

      // Sort drivers:
      // 1) Total points (desc)
      // 2) Wins (desc)
      // 3) Driver name (asc)
      standingsList.sort((a, b) {
        if (b.totalPoints != a.totalPoints) {
          return b.totalPoints.compareTo(a.totalPoints);
        }
        if (b.wins != a.wins) {
          return b.wins.compareTo(a.wins);
        }
        return a.driverName.compareTo(b.driverName);
      });

      setState(() {
        _standings = standingsList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading standings: $e';
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Standings – ${widget.division.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _standings.isEmpty
                  ? const Center(
                      child:
                          Text('No classified results yet for this division.'),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadStandings,
                      child: ListView.builder(
                        itemCount: _standings.length,
                        itemBuilder: (context, index) {
                          final standing = _standings[index];
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
                          );
                        },
                      ),
                    ),
    );
  }
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

/// Internal helper to represent classification for a single event.
class _EventClassificationEntry {
  final String driverId;
  final String driverName;
  final int baseTimeMs;
  final int adjustedTimeMs;

  _EventClassificationEntry({
    required this.driverId,
    required this.driverName,
    required this.baseTimeMs,
    required this.adjustedTimeMs,
  });
}
