import 'package:flutter/material.dart';

import '../models/league.dart';
import '../models/competition.dart';
import '../models/division.dart';
import '../models/event.dart';
import '../models/driver.dart';
import '../models/session_result.dart';
import '../repositories/event_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/session_result_repository.dart';

class StandingsPage extends StatefulWidget {
  final League league;
  final Competition competition;
  final Division division;
  final EventRepository eventRepository;
  final DriverRepository driverRepository;
  final SessionResultRepository sessionResultRepository;

  const StandingsPage({
    super.key,
    required this.league,
    required this.competition,
    required this.division,
    required this.eventRepository,
    required this.driverRepository,
    required this.sessionResultRepository,
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
      // 1) Get all events for this division
      final List<Event> events =
          await widget.eventRepository.getEventsForDivision(widget.division.id);

      if (events.isEmpty) {
        setState(() {
          _isLoading = false;
          _standings = [];
        });
        return;
      }

      // Map of driverId -> standing
      final Map<String, _DriverStanding> standingsMap = {};

      for (final event in events) {
        // 2) Get results for this event
        final List<SessionResult> results =
            widget.sessionResultRepository.getResultsForEvent(event.id);

        if (results.isEmpty) {
          continue;
        }

        // 3) Get driver details for this event to resolve names
        final List<Driver> eventDrivers =
            await widget.driverRepository.getDriversForEvent(event.id);
        final Map<String, Driver> driverById = {
          for (final d in eventDrivers) d.id: d,
        };

        for (final result in results) {
          final finish = result.finishPosition;
          if (finish == null) {
            // No classified finish -> ignore for points
            continue;
          }

          final points = _pointsForFinish(finish);
          if (points <= 0) {
            // If you want only top X to score, this is enough
            continue;
          }

          final driverId = result.driverId;
          final driver = driverById[driverId];
          final driverName = driver?.name ?? 'Unknown Driver';

          if (!standingsMap.containsKey(driverId)) {
            standingsMap[driverId] = _DriverStanding(
              driverId: driverId,
              driverName: driverName,
              totalPoints: 0,
              wins: 0,
            );
          }

          final standing = standingsMap[driverId]!;
          standing.totalPoints += points;
          if (finish == 1) {
            standing.wins += 1;
          }
        }
      }

      final standingsList = standingsMap.values.toList()
        ..sort((a, b) {
          // Sort by:
          // 1) Total points (desc)
          // 2) Wins (desc)
          // 3) Driver name (asc)
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
    // Simple F1-style scoring for top 10; adjust later if needed
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

                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(position.toString()),
                            ),
                            title: Text(standing.driverName),
                            subtitle: Text(
                              'Points: ${standing.totalPoints} • Wins: ${standing.wins}',
                            ),
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
  int totalPoints;
  int wins;

  _DriverStanding({
    required this.driverId,
    required this.driverName,
    required this.totalPoints,
    required this.wins,
  });
}
