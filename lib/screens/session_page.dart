// lib/screens/session_page.dart

import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/driver.dart';
import '../models/session_result.dart';
import '../models/validation_issue.dart';
import '../repositories/driver_repository.dart';
import '../repositories/session_result_repository.dart';
import '../repositories/validation_issue_repository.dart';
import 'package:flutter/services.dart';


class SessionPage extends StatefulWidget {
  final Event event;
  final DriverRepository driverRepository;
  final SessionResultRepository sessionResultRepository;
  final ValidationIssueRepository validationIssueRepository;

  const SessionPage({
    super.key,
    required this.event,
    required this.driverRepository,
    required this.sessionResultRepository,
    required this.validationIssueRepository,
  });

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  final List<Driver> _drivers = [];
  final Map<String, SessionResult> _resultsByDriverId = {};

  final Map<String, TextEditingController> _gridControllers = {};
  final Map<String, TextEditingController> _finishControllers = {};
  final Map<String, TextEditingController> _timeControllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final drivers =
          await widget.driverRepository.getDriversForEvent(widget.event.id);
      final existingResults =
          widget.sessionResultRepository.getResultsForEvent(widget.event.id);

      _drivers
        ..clear()
        ..addAll(drivers);

      _resultsByDriverId.clear();

      final existingByDriverId = {
        for (final r in existingResults) r.driverId: r,
      };

      for (final driver in _drivers) {
        final existing = existingByDriverId[driver.id];

        final result = SessionResult(
          driverId: driver.id,
          gridPosition: existing?.gridPosition,
          finishPosition: existing?.finishPosition,
          raceTimeMillis: existing?.raceTimeMillis,
        );

        _resultsByDriverId[driver.id] = result;

        _gridControllers[driver.id] = TextEditingController(
          text: existing?.gridPosition?.toString() ?? '',
        );
        _finishControllers[driver.id] = TextEditingController(
          text: existing?.finishPosition?.toString() ?? '',
        );
        _timeControllers[driver.id] = TextEditingController(
          text: existing?.raceTimeMillis != null
              ? _formatAbsoluteTime(existing!.raceTimeMillis!)
              : '',
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadError = 'Error loading session data: $e';
      });
    }
  }

  void _updateGridPosition(String driverId, String value) {
    final trimmed = value.trim();
    final result = _resultsByDriverId[driverId];
    if (result == null) return;

    if (trimmed.isEmpty) {
      result.gridPosition = null;
    } else {
      final parsed = int.tryParse(trimmed);
      result.gridPosition = parsed;
    }
  }

  void _updateFinishPosition(String driverId, String value) {
    final trimmed = value.trim();
    final result = _resultsByDriverId[driverId];
    if (result == null) return;

    if (trimmed.isEmpty) {
      result.finishPosition = null;
    } else {
      final parsed = int.tryParse(trimmed);
      result.finishPosition = parsed;
    }
  }

  void _updateRaceTime(String driverId, String value) {
    final trimmed = value.trim();
    final result = _resultsByDriverId[driverId];
    if (result == null) return;

    if (trimmed.isEmpty) {
      result.raceTimeMillis = null;
      return;
    }

    final ms = _parseRaceTimeMillis(trimmed);
    result.raceTimeMillis = ms;
  }

  /// Parses race time strings such as:
  /// - "1:14:40.727"  → 1h 14m 40.727s
  /// - "14:40.727"    → 14m 40.727s
  /// - "40.727"       → 40.727s
  int? _parseRaceTimeMillis(String input) {
    var s = input.trim();
    if (s.isEmpty) return null;

    // Allow optional leading '+'
    if (s.startsWith('+')) {
      s = s.substring(1).trim();
    }

    final parts = s.split(':');
    if (parts.length > 3) {
      return null;
    }

    double secondsPart;
    int minutesPart = 0;
    int hoursPart = 0;

    if (parts.length == 1) {
      // "SS.SSS"
      secondsPart = double.tryParse(parts[0]) ?? double.nan;
    } else if (parts.length == 2) {
      // "MM:SS.SSS"
      minutesPart = int.tryParse(parts[0]) ?? -1;
      secondsPart = double.tryParse(parts[1]) ?? double.nan;
    } else {
      // "HH:MM:SS.SSS"
      hoursPart = int.tryParse(parts[0]) ?? -1;
      minutesPart = int.tryParse(parts[1]) ?? -1;
      secondsPart = double.tryParse(parts[2]) ?? double.nan;
    }

    if (secondsPart.isNaN || minutesPart < 0 || hoursPart < 0) {
      return null;
    }

    final totalMs = (secondsPart * 1000).round() +
        (minutesPart * 60 * 1000) +
        (hoursPart * 60 * 60 * 1000);
    return totalMs;
  }

  Future<void> _saveResults() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final results = _resultsByDriverId.values.toList();
      final issues = <ValidationIssue>[];

      final driversById = {
        for (final d in _drivers) d.id: d,
      };

      final driverCount = _drivers.length;

      // 1) Validate required fields: grid, finish, time
      for (final result in results) {
        final driver = driversById[result.driverId];
        final driverName = driver?.name ?? 'Unknown driver';

        if (result.gridPosition == null) {
          issues.add(
            _buildIssue(
              eventId: widget.event.id,
              driverId: result.driverId,
              code: 'MISSING_GRID',
              message: 'Missing GRID position for $driverName.',
            ),
          );
        }

        if (result.finishPosition == null) {
          issues.add(
            _buildIssue(
              eventId: widget.event.id,
              driverId: result.driverId,
              code: 'MISSING_FINISH',
              message: 'Missing FINISH position for $driverName.',
            ),
          );
        }

        if (result.raceTimeMillis == null) {
          issues.add(
            _buildIssue(
              eventId: widget.event.id,
              driverId: result.driverId,
              code: 'MISSING_TIME',
              message:
                  'Missing race time for $driverName. Please enter a time such as 1:14:40.727.',
            ),
          );
        }
      }

      // 2) Duplicate grid positions
      final Map<int, List<SessionResult>> gridMap = {};
      for (final result in results) {
        final grid = result.gridPosition;
        if (grid == null) continue;
        gridMap.putIfAbsent(grid, () => []).add(result);
      }

      gridMap.forEach((grid, list) {
        if (list.length > 1) {
          final names = list
              .map((r) => driversById[r.driverId]?.name ?? 'Unknown driver')
              .join(', ');
          issues.add(
            _buildIssue(
              eventId: widget.event.id,
              code: 'DUPLICATE_GRID',
              message: 'Duplicate GRID position $grid for: $names.',
            ),
          );
        }
      });

      // 3) Duplicate finish positions
      final Map<int, List<SessionResult>> finishMap = {};
      for (final result in results) {
        final finish = result.finishPosition;
        if (finish == null) continue;
        finishMap.putIfAbsent(finish, () => []).add(result);
      }

      finishMap.forEach((finish, list) {
        if (list.length > 1) {
          final names = list
              .map((r) => driversById[r.driverId]?.name ?? 'Unknown driver')
              .join(', ');
          issues.add(
            _buildIssue(
              eventId: widget.event.id,
              code: 'DUPLICATE_FINISH',
              message: 'Duplicate FINISH position $finish for: $names.',
            ),
          );
        }
      });

      // 4) Invalid finish range
      for (final result in results) {
        final finish = result.finishPosition;
        if (finish == null) continue;
        if (finish < 1 || finish > driverCount) {
          final driverName =
              driversById[result.driverId]?.name ?? 'Unknown driver';
          issues.add(
            _buildIssue(
              eventId: widget.event.id,
              driverId: result.driverId,
              code: 'INVALID_FINISH_RANGE',
              message:
                  'Finish position for $driverName should be between 1 and $driverCount.',
            ),
          );
        }
      }

      if (issues.isNotEmpty) {
        widget.validationIssueRepository
            .replaceIssuesForEvent(widget.event.id, issues);

        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Validation issues'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: issues
                      .map(
                        (i) => ListTile(
                          leading: const Icon(Icons.warning_amber_outlined),
                          title: Text(i.message),
                          subtitle: Text(i.code),
                        ),
                      )
                      .toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        setState(() {
          _isSaving = false;
        });
        return;
      }

      // No issues: clear, save results
      widget.validationIssueRepository.clearIssuesForEvent(widget.event.id);
      widget.sessionResultRepository
          .saveResultsForEvent(widget.event.id, results);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session results saved.')),
      );

      setState(() {
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving results: $e')),
      );
    }
  }

  ValidationIssue _buildIssue({
    required String eventId,
    String? driverId,
    required String code,
    required String message,
  }) {
    final now = DateTime.now();
    final id =
        '${eventId}_${driverId ?? 'GEN'}_${code}_${now.millisecondsSinceEpoch}';

    return ValidationIssue(
      id: id,
      eventId: eventId,
      driverId: driverId,
      code: code,
      message: message,
      createdAt: now,
      isResolved: false,
    );
  }

  String _formatAbsoluteTime(int ms) {
    final duration = Duration(milliseconds: ms);

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    final millis = duration.inMilliseconds % 1000;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}.'
          '${millis.toString().padLeft(3, '0')}';
    } else {
      return '${minutes.toString().padLeft(1, '0')}:'
          '${seconds.toString().padLeft(2, '0')}.'
          '${millis.toString().padLeft(3, '0')}';
    }
  }

  String _formatGap(int msGap) {
    final seconds = msGap / 1000.0;
    return '+${seconds.toStringAsFixed(3)}';
  }

  Widget _buildCurrentResultsSummary() {
    final resultsWithTime = _resultsByDriverId.values
        .where((r) => r.raceTimeMillis != null)
        .toList();

    if (resultsWithTime.isEmpty) {
      return const SizedBox.shrink();
    }

    resultsWithTime.sort(
      (a, b) => a.raceTimeMillis!.compareTo(b.raceTimeMillis!),
    );

    final leaderTimeMs = resultsWithTime.first.raceTimeMillis!;
    final driverById = {for (final d in _drivers) d.id: d};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text(
          'Current results (by time)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...resultsWithTime.map((result) {
          final driver = driverById[result.driverId];
          final driverName = driver?.name ?? 'Unknown driver';

          final pos = result.finishPosition;
          final posLabel = pos != null ? 'P$pos' : '--';

          final timeMs = result.raceTimeMillis!;
          final text = timeMs == leaderTimeMs
              ? _formatAbsoluteTime(timeMs)
              : _formatGap(timeMs - leaderTimeMs);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('$posLabel: $driverName – $text'),
          );
        }),
      ],
    );
  }

  @override
  void dispose() {
    for (final c in _gridControllers.values) {
      c.dispose();
    }
    for (final c in _finishControllers.values) {
      c.dispose();
    }
    for (final c in _timeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Results – ${widget.event.name}'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Results – ${widget.event.name}'),
        ),
        body: Center(
          child: Text(_loadError!),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Results – ${widget.event.name}'),
      ),
      body: Column(
        children: [
          if (_isSaving)
            const LinearProgressIndicator(
              minHeight: 2,
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._drivers.map(_buildDriverRow),
                const SizedBox(height: 16),
                _buildCurrentResultsSummary(),
                const SizedBox(height: 16),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveResults,
                  icon: const Icon(Icons.save),
                  label: const Text('Save results'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverRow(Driver driver) {
    // ignore: unused_local_variable
    final result = _resultsByDriverId[driver.id]!;

    final gridController = _gridControllers[driver.id]!;
    final finishController = _finishControllers[driver.id]!;
    final timeController = _timeControllers[driver.id]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              driver.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: gridController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Grid',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) =>
                        _updateGridPosition(driver.id, value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: finishController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Finish',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) =>
                        _updateFinishPosition(driver.id, value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: timeController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                RaceTimeInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Race time',
                hintText: '_:__:__.___  (H:MM:SS.mmm)',
                helperText: 'Example: 1:14:40.727',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _updateRaceTime(driver.id, value),
            ),
          ],
        ),
      ),
    );
  }
}

class RaceTimeInputFormatter extends TextInputFormatter {
  // We expect exactly 8 digits: H MM SS mmm  →  1 + 2 + 2 + 3
  static const int _maxDigits = 8;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove anything that isn't a digit
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > _maxDigits) {
      digits = digits.substring(0, _maxDigits);
    }

    final buffer = StringBuffer();
    final len = digits.length;

    // Hours (1 digit)
    if (len >= 1) {
      buffer.write(digits[0]);
    }

    // Minutes (2 digits)
    if (len >= 2) {
      buffer.write(':');
      final end = len >= 3 ? 3 : len;
      buffer.write(digits.substring(1, end));
    }

    // Seconds (2 digits)
    if (len >= 4) {
      buffer.write(':');
      final end = len >= 5 ? 5 : len;
      buffer.write(digits.substring(3, end));
    }

    // Milliseconds (3 digits)
    if (len >= 6) {
      buffer.write('.');
      buffer.write(digits.substring(5));
    }

    final text = buffer.toString();

    return TextEditingValue(
      text: text,
      // Always keep cursor at the end of the formatted string
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
