import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/event.dart';
import '../models/driver.dart';
import '../models/session_result.dart';
import '../models/validation_issue.dart';
import '../repositories/driver_repository.dart';
import '../repositories/session_result_repository.dart';
import '../repositories/validation_issue_repository.dart';
import '../repositories/penalty_repository.dart';
import 'validation_issues_page.dart';

class SessionPage extends StatefulWidget {
  final Event event;
  final DriverRepository driverRepository;
  final SessionResultRepository sessionResultRepository;
  final ValidationIssueRepository validationIssueRepository;
  final PenaltyRepository penaltyRepository;

  const SessionPage({
    super.key,
    required this.event,
    required this.driverRepository,
    required this.sessionResultRepository,
    required this.validationIssueRepository,
    required this.penaltyRepository,
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

  // New: pole & fastest lap
  final TextEditingController _poleLapTimeController = TextEditingController();
  final TextEditingController _fastestLapTimeController =
      TextEditingController();
  String? _selectedFastestLapDriverId;

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
      _gridControllers.clear();
      _finishControllers.clear();
      _timeControllers.clear();

      _poleLapTimeController.clear();
      _fastestLapTimeController.clear();
      _selectedFastestLapDriverId = null;

      final existingByDriverId = {
        for (final r in existingResults) r.driverId: r,
      };

      // Build per-driver result objects and controllers
      for (final driver in _drivers) {
        final existing = existingByDriverId[driver.id];

        final result = SessionResult(
          driverId: driver.id,
          gridPosition: existing?.gridPosition,
          finishPosition: existing?.finishPosition,
          raceTimeMillis: existing?.raceTimeMillis,
          hasFastestLap: existing?.hasFastestLap ?? false,
          fastestLapMillis: existing?.fastestLapMillis,
          poleLapMillis: existing?.poleLapMillis,
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

      // If an existing fastest lap is stored, restore selection + time
      for (final r in existingResults) {
        if (r.hasFastestLap && _drivers.any((d) => d.id == r.driverId)) {
          _selectedFastestLapDriverId = r.driverId;
          if (r.fastestLapMillis != null) {
            _fastestLapTimeController.text =
                _formatAbsoluteTime(r.fastestLapMillis!);
          }
          break;
        }
      }

      // If an existing pole lap time is stored, restore it
      SessionResult? existingPole;
      for (final r in existingResults) {
        if (r.poleLapMillis != null) {
          existingPole = r;
          break;
        }
      }
      if (existingPole != null && existingPole.poleLapMillis != null) {
        _poleLapTimeController.text =
            _formatAbsoluteTime(existingPole.poleLapMillis!);
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

      // 5) Fastest lap & pole lap (new)
      // Reset flags
      for (final r in results) {
        r.hasFastestLap = false;
        r.fastestLapMillis = null;
        r.poleLapMillis = null;
      }

      // Fastest lap
      final fastestDriverId = _selectedFastestLapDriverId;
      final fastestText = _fastestLapTimeController.text.trim();
      if (fastestDriverId != null && fastestText.isNotEmpty) {
        final fastestMs = _parseRaceTimeMillis(fastestText);
        if (fastestMs == null) {
          issues.add(
            _buildIssue(
              eventId: widget.event.id,
              driverId: fastestDriverId,
              code: 'INVALID_FASTEST_LAP_TIME',
              message:
                  'Fastest lap time format is invalid. Please use H:MM:SS.mmm.',
            ),
          );
        } else {
          final result = _resultsByDriverId[fastestDriverId];
          if (result == null) {
            issues.add(
              _buildIssue(
                eventId: widget.event.id,
                driverId: fastestDriverId,
                code: 'FASTEST_LAP_DRIVER_NOT_FOUND',
                message:
                    'Selected fastest lap driver does not have a race result.',
              ),
            );
          } else {
            result.hasFastestLap = true;
            result.fastestLapMillis = fastestMs;
          }
        }
      }

      // Pole lap
      final poleText = _poleLapTimeController.text.trim();
      if (poleText.isNotEmpty) {
        final poleMs = _parseRaceTimeMillis(poleText);
        if (poleMs == null) {
          issues.add(
            _buildIssue(
              eventId: widget.event.id,
              code: 'INVALID_POLE_LAP_TIME',
              message:
                  'Pole lap time format is invalid. Please use H:MM:SS.mmm.',
            ),
          );
        } else {
          SessionResult? poleResult;
          for (final r in results) {
            if (r.gridPosition == 1) {
              poleResult = r;
              break;
            }
          }
          if (poleResult == null) {
            issues.add(
              _buildIssue(
                eventId: widget.event.id,
                code: 'POLE_DRIVER_NOT_FOUND',
                message:
                    'Cannot assign a pole lap time because no driver has grid position 1 yet.',
              ),
            );
          } else {
            poleResult.poleLapMillis = poleMs;
          }
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
                          leading:
                              const Icon(Icons.warning_amber_outlined),
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
      return '$hours:${minutes.toString().padLeft(2, '0')}:' // HH:MM:
          '${seconds.toString().padLeft(2, '0')}.'           // SS.
          '${millis.toString().padLeft(3, '0')}';            // mmm
    } else {
      return '${minutes.toString().padLeft(1, '0')}:'        // M:
          '${seconds.toString().padLeft(2, '0')}.'           // SS.
          '${millis.toString().padLeft(3, '0')}';            // mmm
    }
  }

  String _formatGap(int msGap) {
    final seconds = msGap / 1000.0;
    return '+${seconds.toStringAsFixed(3)}';
  }

  /// Uses race times + time penalties to show the live classification.
  Widget _buildCurrentResultsSummary() {
    final resultsWithTime = _resultsByDriverId.values
        .where((r) => r.raceTimeMillis != null)
        .toList();

    if (resultsWithTime.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get time penalties for this event
    final penalties =
        widget.penaltyRepository.getPenaltiesForEvent(widget.event.id);

    // driverId -> total time penalty in seconds
    final Map<String, int> timePenaltySecondsByDriver = {};
    for (final p in penalties) {
      if (p.type == 'Time') {
        timePenaltySecondsByDriver[p.driverId] =
            (timePenaltySecondsByDriver[p.driverId] ?? 0) + p.value;
      }
    }

    final driverById = {for (final d in _drivers) d.id: d};

    // Build working rows with base + adjusted times
    final rows = resultsWithTime.map((result) {
      final baseTimeMs = result.raceTimeMillis!;
      final penaltySec = timePenaltySecondsByDriver[result.driverId] ?? 0;
      final adjustedTimeMs = baseTimeMs + penaltySec * 1000;

      return {
        'result': result,
        'baseTimeMs': baseTimeMs,
        'adjustedTimeMs': adjustedTimeMs,
        'penaltySec': penaltySec,
      };
    }).toList();

    // Sort by adjusted time (true classification)
    rows.sort(
      (a, b) =>
          (a['adjustedTimeMs'] as int).compareTo(b['adjustedTimeMs'] as int),
    );

    final leaderAdjustedMs = rows.first['adjustedTimeMs'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text(
          'Current results (after time penalties)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;

          final result = row['result'] as SessionResult;
          final baseTimeMs = row['baseTimeMs'] as int;
          final adjustedTimeMs = row['adjustedTimeMs'] as int;
          final penaltySec = row['penaltySec'] as int;

          final driver = driverById[result.driverId];
          final driverName = driver?.name ?? 'Unknown driver';

          final positionLabel = 'P${index + 1}';

          final text = adjustedTimeMs == leaderAdjustedMs
              ? _formatAbsoluteTime(baseTimeMs)
              : _formatGap(adjustedTimeMs - leaderAdjustedMs);

          final penaltyNote = penaltySec != 0
              ? ' (includes ${penaltySec > 0 ? '+$penaltySec' : penaltySec}s)'
              : '';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('$positionLabel: $driverName – $text$penaltyNote'),
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
    _poleLapTimeController.dispose();
    _fastestLapTimeController.dispose();
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

    // get current issues for this event to show a badge if needed
    final issues =
        widget.validationIssueRepository.getIssuesForEvent(widget.event.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Results – ${widget.event.name}'),
        actions: [
          IconButton(
            tooltip: 'View validation issues',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ValidationIssuesPage(
                    event: widget.event,
                    validationIssueRepository:
                        widget.validationIssueRepository,
                  ),
                ),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.report_problem_outlined),
                if (issues.isNotEmpty)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
                _buildQualifyingAndFastestLapSection(),
                const SizedBox(height: 16),
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

  Widget _buildQualifyingAndFastestLapSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Qualifying & fastest lap',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _poleLapTimeController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                RaceTimeInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Pole lap time',
                hintText: '_:__:__.___  (H:MM:SS.mmm)',
                helperText: 'Example: 1:14:40.727',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedFastestLapDriverId,
              decoration: const InputDecoration(
                labelText: 'Fastest lap – driver',
                border: OutlineInputBorder(),
              ),
              items: _drivers
                  .map(
                    (d) => DropdownMenuItem<String>(
                      value: d.id,
                      child: Text(d.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFastestLapDriverId = value;
                });
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fastestLapTimeController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                RaceTimeInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Fastest lap time',
                hintText: '_:__:__.___  (H:MM:SS.mmm)',
                helperText: 'Example: 1:17:09.832',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverRow(Driver driver) {
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

/// Input formatter that locks the race time field to H:MM:SS.mmm
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
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
