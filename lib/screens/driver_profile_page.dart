// lib/screens/driver_profile_page.dart

import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../models/division.dart';
import '../models/event.dart';
import '../models/session_result.dart';
import '../models/penalty.dart';

import '../repositories/event_repository.dart';
import '../repositories/session_result_repository.dart';
import '../repositories/penalty_repository.dart';

class DriverProfilePage extends StatefulWidget {
  final Driver driver;
  final Division division;
  final EventRepository eventRepository;
  final SessionResultRepository sessionResultRepository;
  final PenaltyRepository penaltyRepository;

  const DriverProfilePage({
    super.key,
    required this.driver,
    required this.division,
    required this.eventRepository,
    required this.sessionResultRepository,
    required this.penaltyRepository,
  });

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  late Future<_DriverStats> _futureStats;

  @override
  void initState() {
    super.initState();
    _futureStats = _loadStats();
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

  Future<_DriverStats> _loadStats() async {
    final driver = widget.driver;

    final List<Event> events =
        await widget.eventRepository.getEventsForDivision(widget.division.id);

    if (events.isEmpty) {
      return const _DriverStats.empty();
    }

    int races = 0;
    int basePoints = 0;
    int penaltyPoints = 0;
    int totalPoints = 0;

    int fastestLaps = 0;
    int polePositions = 0;

    int totalFinishPos = 0;
    int finishCount = 0;

    int totalGainedPositions = 0;

    for (final event in events) {
      final List<SessionResult> results =
          widget.sessionResultRepository.getResultsForEvent(event.id);

      final List<SessionResult> forDriver =
          results.where((r) => r.driverId == driver.id).toList();

      if (forDriver.isEmpty) {
        continue;
      }

      // For now assume one result per driver per event.
      final SessionResult result = forDriver.first;
      races++;

      // Fastest lap
      if (result.hasFastestLap == true) {
        fastestLaps++;
      }

      // Pole position (grid = 1)
      if (result.gridPosition == 1) {
        polePositions++;
      }

      // Finish stats
      if (result.finishPosition != null) {
        totalFinishPos += result.finishPosition!;
        finishCount++;

        final pts = _pointsForFinish(result.finishPosition!);
        basePoints += pts;
        totalPoints += pts;
      }

      // Gained positions (grid - finish; positive = net gain)
      if (result.gridPosition != null && result.finishPosition != null) {
        totalGainedPositions +=
            (result.gridPosition! - result.finishPosition!);
      }

      // Points penalties for this event
      final List<Penalty> eventPenalties =
          widget.penaltyRepository.getPenaltiesForEvent(event.id);

      for (final p in eventPenalties) {
        if (p.driverId == driver.id && p.type == 'Points') {
          penaltyPoints += p.value;
          totalPoints += p.value;
        }
      }
    }

    final double avgFinish =
        finishCount > 0 ? totalFinishPos / finishCount : 0.0;
    final double pointsPerRace =
        races > 0 ? totalPoints / races : 0.0;

    return _DriverStats(
      races: races,
      basePoints: basePoints,
      penaltyPoints: penaltyPoints,
      totalPoints: totalPoints,
      fastestLaps: fastestLaps,
      polePositions: polePositions,
      totalGainedPositions: totalGainedPositions,
      averageFinishPosition: avgFinish,
      pointsPerRace: pointsPerRace,
    );
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.driver;

    return Scaffold(
      appBar: AppBar(
        title: Text(driver.name),
      ),
      body: FutureBuilder<_DriverStats>(
        future: _futureStats,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading stats: ${snapshot.error}'),
            );
          }

          final stats = snapshot.data ?? const _DriverStats.empty();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(driver),
                const SizedBox(height: 16),
                _buildSeasonSummaryCard(stats),
                const SizedBox(height: 16),
                _buildPerformanceGrid(stats),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(Driver driver) {
    final teamName =
        (driver.teamName == null || driver.teamName!.trim().isEmpty)
            ? 'Unknown Team'
            : driver.teamName!;
    final numberText =
        driver.number != null ? '#${driver.number}' : 'No. N/A';
    final nationalityText = driver.nationality ?? 'Nationality unknown';

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(
                driver.name.isNotEmpty
                    ? driver.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    teamName,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$numberText • $nationalityText',
                    style: const TextStyle(
                      fontSize: 12,
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

  Widget _buildSeasonSummaryCard(_DriverStats stats) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Season Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _smallStat('Races', stats.races.toString()),
                _smallStat('Total Points', stats.totalPoints.toString()),
                _smallStat('Base Points', stats.basePoints.toString()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _smallStat(
                  'Penalty Points',
                  stats.penaltyPoints.toString(),
                ),
                _smallStat(
                  'Pts / Race',
                  stats.pointsPerRace.toStringAsFixed(2),
                ),
                _smallStat(
                  'Avg Finish',
                  stats.races == 0
                      ? 'N/A'
                      : stats.averageFinishPosition.toStringAsFixed(2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceGrid(_DriverStats stats) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3.0,
              children: [
                _bigStat('Fastest Laps', stats.fastestLaps.toString()),
                _bigStat('Pole Positions', stats.polePositions.toString()),
                _bigStat(
                  'Net Gained Positions',
                  stats.totalGainedPositions.toString(),
                ),
                _bigStat(
                  'Races Classified',
                  stats.races.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _bigStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _DriverStats {
  final int races;
  final int basePoints;
  final int penaltyPoints;
  final int totalPoints;

  final int fastestLaps;
  final int polePositions;
  final int totalGainedPositions;

  final double averageFinishPosition;
  final double pointsPerRace;

  const _DriverStats({
    required this.races,
    required this.basePoints,
    required this.penaltyPoints,
    required this.totalPoints,
    required this.fastestLaps,
    required this.polePositions,
    required this.totalGainedPositions,
    required this.averageFinishPosition,
    required this.pointsPerRace,
  });

  const _DriverStats.empty()
      : races = 0,
        basePoints = 0,
        penaltyPoints = 0,
        totalPoints = 0,
        fastestLaps = 0,
        polePositions = 0,
        totalGainedPositions = 0,
        averageFinishPosition = 0.0,
        pointsPerRace = 0.0;
}
