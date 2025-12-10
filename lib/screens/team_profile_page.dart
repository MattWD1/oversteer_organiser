// lib/screens/team_profile_page.dart

import 'package:flutter/material.dart';

import '../models/league.dart';
import '../models/driver.dart';
import '../models/division.dart';

import '../repositories/competition_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/session_result_repository.dart';
import '../repositories/penalty_repository.dart';

class TeamProfilePage extends StatefulWidget {
  final String teamName;
  final League league;
  final Division? division; // Optional: if provided, show division-specific stats
  final CompetitionRepository competitionRepository;
  final EventRepository eventRepository;
  final DriverRepository driverRepository;
  final SessionResultRepository sessionResultRepository;
  final PenaltyRepository penaltyRepository;

  const TeamProfilePage({
    super.key,
    required this.teamName,
    required this.league,
    this.division,
    required this.competitionRepository,
    required this.eventRepository,
    required this.driverRepository,
    required this.sessionResultRepository,
    required this.penaltyRepository,
  });

  @override
  State<TeamProfilePage> createState() => _TeamProfilePageState();
}

class _TeamProfilePageState extends State<TeamProfilePage> {
  bool _isLoadingStats = true;
  String? _statsError;

  int _races = 0;
  int _wins = 0;
  int _podiums = 0;
  int _fastestLaps = 0;
  int _positionsGained = 0;
  double _avgFinish = 0;
  double _pointsPerRace = 0;
  int _penaltyPoints = 0;
  int _totalPoints = 0;
  List<String> _teamDrivers = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
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

  String _getTeamName(Driver driver) {
    try {
      final dynamic d = driver;
      final value = d.teamName;
      if (value is String && value.isNotEmpty) {
        return value;
      }
    } catch (_) {}
    return 'Unknown Team';
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoadingStats = true;
      _statsError = null;
    });

    try {
      // Get divisions to process (either single division or all divisions for league)
      final List<dynamic> divisions;
      if (widget.division != null) {
        // Division-specific stats
        divisions = [widget.division!];
      } else {
        // League-wide stats
        divisions = await widget.competitionRepository.getDivisionsForLeague(
          widget.league.id,
        );
      }

      int races = 0;
      int wins = 0;
      int podiums = 0;
      int fastestLaps = 0;
      int positionsGained = 0;
      int totalFinish = 0;
      int totalPoints = 0;
      int penaltyPoints = 0;
      Set<String> driverNames = {};
      int resultCount = 0;

      for (final division in divisions) {
        final events = await widget.eventRepository.getEventsForDivision(
          division.id,
        );

        for (final event in events) {
          final results = widget.sessionResultRepository.getResultsForEvent(
            event.id,
          );

          final eventDrivers = await widget.driverRepository.getDriversForEvent(
            event.id,
          );
          final Map<String, Driver> driverById = {
            for (final d in eventDrivers) d.id: d,
          };

          // Filter results for this team's drivers
          final teamResults = results.where((result) {
            final driver = driverById[result.driverId];
            return driver != null && _getTeamName(driver) == widget.teamName;
          }).toList();

          if (teamResults.isEmpty) continue;

          races++;

          // Track unique driver names
          for (final result in teamResults) {
            final driver = driverById[result.driverId];
            if (driver != null) {
              driverNames.add(driver.name);
            }
          }

          // Find best finishing position from team drivers
          int? bestFinish;
          for (final result in teamResults) {
            if (result.finishPosition != null) {
              if (bestFinish == null ||
                  result.finishPosition! < bestFinish) {
                bestFinish = result.finishPosition;
              }
            }
          }

          if (bestFinish != null) {
            totalFinish += bestFinish;
            resultCount++;
            if (bestFinish == 1) wins++;
            if (bestFinish <= 3) podiums++;
          }

          // Count fastest laps from team drivers
          for (final result in teamResults) {
            if (result.hasFastestLap == true) {
              fastestLaps++;
            }

            // Positions gained
            if (result.gridPosition != null &&
                result.finishPosition != null) {
              positionsGained +=
                  (result.gridPosition! - result.finishPosition!);
            }
          }

          // Calculate points for this event (sum all team drivers)
          final eventPenalties = widget.penaltyRepository.getPenaltiesForEvent(
            event.id,
          );

          for (final result in teamResults) {
            final basePoints = _pointsForFinish(result.finishPosition ?? 0);
            int driverEventPoints = basePoints;

            // Apply penalties for this driver
            for (final p in eventPenalties) {
              if (p.driverId == result.driverId && p.type == 'Points') {
                driverEventPoints += p.value;
                penaltyPoints += p.value;
              }
            }

            totalPoints += driverEventPoints;
          }
        }
      }

      setState(() {
        _races = races;
        _wins = wins;
        _podiums = podiums;
        _fastestLaps = fastestLaps;
        _positionsGained = positionsGained;
        _penaltyPoints = penaltyPoints;
        _totalPoints = totalPoints;
        _avgFinish = resultCount > 0 ? totalFinish / resultCount : 0.0;
        _pointsPerRace = races > 0 ? totalPoints / races : 0.0;
        _teamDrivers = driverNames.toList()..sort();
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
        _statsError = 'Error loading stats: $e';
      });
    }
  }

  Widget _buildProfileHeader() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(
                widget.teamName.isNotEmpty
                    ? widget.teamName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.teamName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.division != null
                        ? '${widget.division!.name} - Constructor'
                        : '${widget.league.name} - Constructor',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_statsError != null) {
      return Center(child: Text(_statsError!));
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.division != null
                  ? 'Team statistics (${widget.division!.name})'
                  : 'Team statistics (all divisions)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _statTile('Races', _races.toString()),
                _statTile('Wins', _wins.toString()),
                _statTile('Podiums', _podiums.toString()),
                _statTile('Fastest laps', _fastestLaps.toString()),
                _statTile('Pos. gained', _positionsGained.toString()),
                _statTile(
                  'Avg. finish',
                  _races > 0 ? _avgFinish.toStringAsFixed(2) : '-',
                ),
                _statTile(
                  'Pts / race',
                  _races > 0 ? _pointsPerRace.toStringAsFixed(2) : '-',
                ),
                _statTile('Penalty points', _penaltyPoints.toString()),
                _statTile('Total points', _totalPoints.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriversCard() {
    if (_isLoadingStats || _teamDrivers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Team drivers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...(_teamDrivers.map(
              (driverName) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      driverName,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Team – ${widget.teamName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildStatsCard(),
            _buildDriversCard(),
          ],
        ),
      ),
    );
  }
}
