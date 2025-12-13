import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/event.dart';
import '../models/driver.dart';
import '../models/league.dart';
import '../models/session_result.dart';
import '../models/validation_issue.dart';
import '../repositories/driver_repository.dart';
import '../repositories/session_result_repository.dart';
import '../repositories/validation_issue_repository.dart';
import '../repositories/penalty_repository.dart';
import '../theme/app_theme.dart';
import 'validation_issues_page.dart';

class SessionPage extends StatefulWidget {
  final League league;
  final Event event;
  final DriverRepository driverRepository;
  final SessionResultRepository sessionResultRepository;
  final ValidationIssueRepository validationIssueRepository;
  final PenaltyRepository penaltyRepository;

  const SessionPage({
    super.key,
    required this.league,
    required this.event,
    required this.driverRepository,
    required this.sessionResultRepository,
    required this.validationIssueRepository,
    required this.penaltyRepository,
  });

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Limit to 8 digits max (H:MM:SS.mmm = 1+2+2+3)
    if (digitsOnly.length > 8) {
      digitsOnly = digitsOnly.substring(0, 8);
    }

    // Auto-format as user types
    String formatted = '';

    if (digitsOnly.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Format based on number of digits entered
    if (digitsOnly.length == 1) {
      // Just hours: "1"
      formatted = digitsOnly;
    } else if (digitsOnly.length == 2) {
      // Hours and first minute digit: "1:2"
      formatted = '${digitsOnly[0]}:${digitsOnly[1]}';
    } else if (digitsOnly.length == 3) {
      // Hours and minutes: "1:24"
      formatted = '${digitsOnly[0]}:${digitsOnly.substring(1, 3)}';
    } else if (digitsOnly.length == 4) {
      // Hours, minutes, first second: "1:24:3"
      formatted = '${digitsOnly[0]}:${digitsOnly.substring(1, 3)}:${digitsOnly[3]}';
    } else if (digitsOnly.length == 5) {
      // Hours, minutes, seconds: "1:24:35"
      formatted = '${digitsOnly[0]}:${digitsOnly.substring(1, 3)}:${digitsOnly.substring(3, 5)}';
    } else if (digitsOnly.length == 6) {
      // Add first millisecond: "1:24:35.1"
      formatted = '${digitsOnly[0]}:${digitsOnly.substring(1, 3)}:${digitsOnly.substring(3, 5)}.${digitsOnly[5]}';
    } else if (digitsOnly.length == 7) {
      // Add second millisecond: "1:24:35.12"
      formatted = '${digitsOnly[0]}:${digitsOnly.substring(1, 3)}:${digitsOnly.substring(3, 5)}.${digitsOnly.substring(5, 7)}';
    } else if (digitsOnly.length == 8) {
      // Complete format: "1:24:35.123"
      formatted = '${digitsOnly[0]}:${digitsOnly.substring(1, 3)}:${digitsOnly.substring(3, 5)}.${digitsOnly.substring(5, 8)}';
    }

    // Validate minutes and seconds don't exceed 59
    if (digitsOnly.length >= 3) {
      final minutes = int.parse(digitsOnly.substring(1, 3));
      if (minutes > 59) {
        return oldValue; // Reject invalid minutes
      }
    }

    if (digitsOnly.length >= 5) {
      final seconds = int.parse(digitsOnly.substring(3, 5));
      if (seconds > 59) {
        return oldValue; // Reject invalid seconds
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Formatter for gap times (2nd place onwards): +MM:SS.mmm format
class _GapTimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Limit to 7 digits max (MM:SS.mmm = 2+2+3)
    if (digitsOnly.length > 7) {
      digitsOnly = digitsOnly.substring(0, 7);
    }

    // Auto-format as user types with + prefix
    String formatted = '';

    if (digitsOnly.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Format based on number of digits entered
    if (digitsOnly.length == 1) {
      // Just first minute digit: "+2"
      formatted = '+$digitsOnly';
    } else if (digitsOnly.length == 2) {
      // Minutes: "+25"
      formatted = '+${digitsOnly.substring(0, 2)}';
    } else if (digitsOnly.length == 3) {
      // Minutes and first second digit: "+25:4"
      formatted = '+${digitsOnly.substring(0, 2)}:${digitsOnly[2]}';
    } else if (digitsOnly.length == 4) {
      // Minutes and seconds: "+25:44"
      formatted = '+${digitsOnly.substring(0, 2)}:${digitsOnly.substring(2, 4)}';
    } else if (digitsOnly.length == 5) {
      // Add first millisecond: "+25:44.3"
      formatted = '+${digitsOnly.substring(0, 2)}:${digitsOnly.substring(2, 4)}.${digitsOnly[4]}';
    } else if (digitsOnly.length == 6) {
      // Add second millisecond: "+25:44.38"
      formatted = '+${digitsOnly.substring(0, 2)}:${digitsOnly.substring(2, 4)}.${digitsOnly.substring(4, 6)}';
    } else if (digitsOnly.length == 7) {
      // Complete format: "+25:44.389"
      formatted = '+${digitsOnly.substring(0, 2)}:${digitsOnly.substring(2, 4)}.${digitsOnly.substring(4, 7)}';
    }

    // Validate minutes and seconds don't exceed 59
    if (digitsOnly.length >= 2) {
      final minutes = int.parse(digitsOnly.substring(0, 2));
      if (minutes > 59) {
        return oldValue; // Reject invalid minutes
      }
    }

    if (digitsOnly.length >= 4) {
      final seconds = int.parse(digitsOnly.substring(2, 4));
      if (seconds > 59) {
        return oldValue; // Reject invalid seconds
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ResultEntry {
  String? driverId; // null means empty slot
  String? teamName;
  int? gridPosition;
  String? status; // null = finished normally, or 'DNF', 'DNS', 'DSQ'
  int? raceTimeMillis;

  _ResultEntry({
    this.driverId,
    this.teamName,
    this.gridPosition,
    this.status,
    this.raceTimeMillis,
  });
}

class _PenaltyEntry {
  String? driverId;
  int? timePenaltySeconds; // Time penalty in seconds (integers only)
  int? penaltyPoints; // Championship penalty points

  _PenaltyEntry({
    // ignore: unused_element_parameter
    this.driverId,
    // ignore: unused_element_parameter
    this.timePenaltySeconds,
    // ignore: unused_element_parameter
    this.penaltyPoints,
  });
}

class _SessionPageState extends State<SessionPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  final List<Driver> _allDrivers = [];
  final List<_ResultEntry> _resultEntries = [];
  final List<_PenaltyEntry> _penaltyEntries = [];
  bool _isPenaltySectionExpanded = true; // Track penalty section expansion

  // Qualifying & fastest lap
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

      _allDrivers
        ..clear()
        ..addAll(drivers);

      _resultEntries.clear();

      // Sort existing results by finish position to maintain order
      final sortedExisting = existingResults.toList()
        ..sort((a, b) {
          if (a.finishPosition == null && b.finishPosition == null) return 0;
          if (a.finishPosition == null) return 1;
          if (b.finishPosition == null) return -1;
          return a.finishPosition!.compareTo(b.finishPosition!);
        });

      // Build result entries based on existing data
      if (sortedExisting.isNotEmpty) {
        for (final existing in sortedExisting) {
          final driver = _allDrivers.firstWhere((d) => d.id == existing.driverId);
          _resultEntries.add(_ResultEntry(
            driverId: existing.driverId,
            teamName: driver.teamName,
            gridPosition: existing.gridPosition,
            status: existing.finishPosition == null ? 'DNF' : null,
            raceTimeMillis: existing.raceTimeMillis,
          ));
        }
      } else {
        // No existing results - create empty entries for all drivers
        // Initialize grid positions to sequential values (1, 2, 3, ...)
        for (int i = 0; i < _allDrivers.length; i++) {
          final driver = _allDrivers[i];
          _resultEntries.add(_ResultEntry(
            driverId: driver.id,
            teamName: driver.teamName,
            gridPosition: i + 1, // Set to actual position instead of null
            status: null,
            raceTimeMillis: null,
          ));
        }
      }

      // Restore fastest lap data
      for (final r in existingResults) {
        if (r.hasFastestLap && _allDrivers.any((d) => d.id == r.driverId)) {
          _selectedFastestLapDriverId = r.driverId;
          if (r.fastestLapMillis != null) {
            _fastestLapTimeController.text =
                _formatAbsoluteTime(r.fastestLapMillis!);
          }
          break;
        }
      }

      // Restore pole lap data
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

  int? _parseRaceTimeMillis(String input) {
    var s = input.trim();
    if (s.isEmpty) return null;

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
      secondsPart = double.tryParse(parts[0]) ?? double.nan;
    } else if (parts.length == 2) {
      minutesPart = int.tryParse(parts[0]) ?? -1;
      secondsPart = double.tryParse(parts[1]) ?? double.nan;
    } else {
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
      final results = <SessionResult>[];
      final issues = <ValidationIssue>[];

      final driversById = {
        for (final d in _allDrivers) d.id: d,
      };

      // Build SessionResult objects from entries
      for (int i = 0; i < _resultEntries.length; i++) {
        final entry = _resultEntries[i];

        // Skip empty entries
        if (entry.driverId == null) continue;

        final finishPosition = i + 1; // Position based on list order
        final hasStatus = entry.status != null; // DNF, DNS, or DSQ

        final result = SessionResult(
          driverId: entry.driverId!,
          gridPosition: entry.gridPosition,
          finishPosition: hasStatus ? null : finishPosition,
          raceTimeMillis: entry.raceTimeMillis,
          status: entry.status,
          hasFastestLap: false,
          fastestLapMillis: null,
          poleLapMillis: null,
        );

        results.add(result);

        final driver = driversById[entry.driverId];
        final driverName = driver?.name ?? 'Unknown driver';

        // Validate required fields
        if (entry.gridPosition == null) {
          issues.add(
            _buildIssue(
              eventId: widget.event.id,
              driverId: entry.driverId,
              code: 'MISSING_GRID',
              message: 'Missing GRID position for $driverName.',
            ),
          );
        }

        if (!hasStatus && entry.raceTimeMillis == null) {
          issues.add(
            _buildIssue(
              eventId: widget.event.id,
              driverId: entry.driverId,
              code: 'MISSING_TIME',
              message:
                  'Missing race time for $driverName. Please enter a time such as 1:14:40.727.',
            ),
          );
        }
      }

      // Check for duplicate grid positions
      final Map<int, List<String>> gridMap = {};
      for (final entry in _resultEntries) {
        if (entry.gridPosition == null || entry.driverId == null) continue;
        gridMap.putIfAbsent(entry.gridPosition!, () => []).add(entry.driverId!);
      }

      gridMap.forEach((grid, driverIds) {
        if (driverIds.length > 1) {
          final names = driverIds
              .map((id) => driversById[id]?.name ?? 'Unknown driver')
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

      // Handle fastest lap
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
          final result = results.firstWhere(
            (r) => r.driverId == fastestDriverId,
            orElse: () => SessionResult(driverId: fastestDriverId),
          );
          result.hasFastestLap = true;
          result.fastestLapMillis = fastestMs;
        }
      }

      // Handle pole lap
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

      // No issues: clear and save results
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
      // Format: H:MM:SS.mmm
      return '$hours:${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}.'
          '${millis.toString().padLeft(3, '0')}';
    } else {
      // Format: M:SS.mmm (for times under 1 hour)
      return '$minutes:${seconds.toString().padLeft(2, '0')}.'
          '${millis.toString().padLeft(3, '0')}';
    }
  }

  String _formatGapTime(int gapMs) {
    final duration = Duration(milliseconds: gapMs);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final millis = duration.inMilliseconds % 1000;

    // Format: +MM:SS.mmm
    return '+${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${millis.toString().padLeft(3, '0')}';
  }

  void _addDriverEntry() {
    setState(() {
      _resultEntries.add(_ResultEntry(
        driverId: null,
        teamName: null,
        gridPosition: _resultEntries.length + 1,
        status: null,
        raceTimeMillis: null,
      ));
    });
  }

  void _removeDriverEntry() {
    if (_resultEntries.isNotEmpty) {
      setState(() {
        _resultEntries.removeLast();
      });
    }
  }

  void _calculateResults() {
    setState(() {
      // Separate drivers with times from those without
      final driversWithTimes = _resultEntries.where((e) => e.raceTimeMillis != null && e.status == null).toList();
      final driversWithStatus = _resultEntries.where((e) => e.status != null).toList();
      final driversWithoutTimes = _resultEntries.where((e) => e.raceTimeMillis == null && e.status == null).toList();

      // Create a list of drivers with adjusted times (for sorting only - doesn't modify original times)
      final driversWithAdjustedTimes = driversWithTimes.map((driver) {
        final penalty = _penaltyEntries.firstWhere(
          (p) => p.driverId == driver.driverId && p.timePenaltySeconds != null && p.timePenaltySeconds! > 0,
          orElse: () => _PenaltyEntry(),
        );

        final adjustedTime = penalty.timePenaltySeconds != null && penalty.timePenaltySeconds! > 0
            ? driver.raceTimeMillis! + (penalty.timePenaltySeconds! * 1000)
            : driver.raceTimeMillis!;

        return {'driver': driver, 'adjustedTime': adjustedTime};
      }).toList();

      // Sort by adjusted time
      driversWithAdjustedTimes.sort((a, b) =>
        (a['adjustedTime'] as int).compareTo(b['adjustedTime'] as int)
      );

      // Extract the sorted drivers
      final sortedDrivers = driversWithAdjustedTimes.map((e) => e['driver'] as _ResultEntry).toList();

      // Rebuild the list: drivers with times first, then DNF/DNS/DSQ, then unfinished
      _resultEntries.clear();
      _resultEntries.addAll(sortedDrivers);
      _resultEntries.addAll(driversWithStatus);
      _resultEntries.addAll(driversWithoutTimes);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _penaltyEntries.any((p) => p.timePenaltySeconds != null && p.timePenaltySeconds! > 0)
              ? 'Results calculated with penalties applied'
              : 'Results calculated and reordered by race time'
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _poleLapTimeController.dispose();
    _fastestLapTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppTheme(
        primaryColor: widget.league.themeColor,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.event.name),
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return AppTheme(
        primaryColor: widget.league.themeColor,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.event.name),
          ),
          body: Center(
            child: Text(_loadError!),
          ),
        ),
      );
    }

    final issues =
        widget.validationIssueRepository.getIssuesForEvent(widget.event.id);

    return AppTheme(
      primaryColor: widget.league.themeColor,
      child: Scaffold(
        body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.grey.shade900,
              widget.league.themeColor.withValues(alpha: 0.4),
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: Column(
          children: [
            AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            if (widget.event.flagEmoji != null) ...[
              Text(
                widget.event.flagEmoji!,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
            ],
            Text(widget.event.name),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'View validation issues',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ValidationIssuesPage(
                    league: widget.league,
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
                      decoration: BoxDecoration(
                        color: widget.league.themeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Save results',
            onPressed: _isSaving ? null : _saveResults,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
          if (_isSaving)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(widget.league.themeColor),
            ),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _buildTrackInfoSection(),
                    const SizedBox(height: 12),
                    // Qualifying and fastest lap section
                    _buildQualifyingAndFastestLapSection(),
                    const SizedBox(height: 16),
                    // Results list
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: _resultEntries.length + 1, // +1 for header
                      onReorder: (oldIndex, newIndex) {
                // Adjust indices to account for header
                if (oldIndex == 0 || newIndex == 0) return;

                setState(() {
                  final actualOldIndex = oldIndex - 1;
                  var actualNewIndex = newIndex - 1;

                  if (actualOldIndex < actualNewIndex) {
                    actualNewIndex -= 1;
                  }

                  final item = _resultEntries.removeAt(actualOldIndex);
                  _resultEntries.insert(actualNewIndex, item);
                });
              },
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Header row
                  return _buildHeaderRow();
                }

                final entryIndex = index - 1;
                final entry = _resultEntries[entryIndex];
                return _buildResultRow(entryIndex, entry);
              },
            ),
            const SizedBox(height: 24),
            // Penalty section
            _buildPenaltySection(),
            const SizedBox(height: 80), // Space for bottom bar
          ],
        ),
      ),
    ),
          ),
          // Bottom bar with calculate, add/remove buttons
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: widget.league.themeColor.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Calculate button (left side)
                ElevatedButton.icon(
                  onPressed: _calculateResults,
                  icon: const Icon(Icons.calculate, size: 20),
                  label: const Text('Calculate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.league.themeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                // Add/Remove buttons (right side)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Remove button
                    IconButton(
                      onPressed: _resultEntries.isEmpty ? null : _removeDriverEntry,
                      icon: const Icon(Icons.remove, size: 24),
                      style: IconButton.styleFrom(
                        backgroundColor: _resultEntries.isEmpty
                            ? Colors.grey.shade800
                            : widget.league.themeColor,
                        foregroundColor: _resultEntries.isEmpty
                            ? Colors.grey.shade600
                            : Colors.white,
                        disabledBackgroundColor: Colors.grey.shade800,
                        disabledForegroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.all(12),
                      ),
                      tooltip: 'Remove Driver',
                    ),
                    const SizedBox(width: 12),
                    // Add button
                    IconButton(
                      onPressed: _addDriverEntry,
                      icon: const Icon(Icons.add, size: 24),
                      style: IconButton.styleFrom(
                        backgroundColor: widget.league.themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                      tooltip: 'Add Driver',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      key: const ValueKey('header'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.9),
            Colors.grey.shade900,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.league.themeColor.withValues(alpha: 0.55),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.league.themeColor.withValues(alpha: 0.35),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 40), // Space for drag handle
          SizedBox(
            width: 30,
            child: Transform.translate(
              offset: const Offset(-25, 0),
              child: const Text(
                'Pos.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Transform.translate(
                  offset: const Offset(-10, 0),
                  child: const Text(
                    'Driver',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 96, // Width for grid +/- buttons
              child: Transform.translate(
                offset: const Offset(-5, 0),
                child: const Text(
                  'Grid',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }

  Widget _buildResultRow(int index, _ResultEntry entry) {
    final position = index + 1;

    return Container(
      key: ValueKey('entry_$index'),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          bottom: BorderSide(
            color: widget.league.themeColor,
            width: 3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.league.themeColor.withValues(alpha: 0.6),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: index + 1, // +1 for header offset
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: const Icon(
                  Icons.drag_indicator,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
            ),
            // Main content in column (two rows)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    // First row: Position | Driver | Grid
                    Row(
                      children: [
                        // Position
                        SizedBox(
                          width: 30,
                          child: Text(
                            '$position',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        // Driver dropdown
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: DropdownButtonFormField<String>(
                              value: entry.driverId,
                              dropdownColor: const Color(0xFF3A3A3A),
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              hint: const Text(
                                'Select driver',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              items: _allDrivers.map((d) {
                                return DropdownMenuItem<String>(
                                  value: d.id,
                                  child: Text(d.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  entry.driverId = value;
                                  if (value != null) {
                                    final selectedDriver =
                                        _allDrivers.firstWhere((d) => d.id == value);
                                    entry.teamName = selectedDriver.teamName;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                        // Grid position with +/- buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                              onPressed: () {
                                setState(() {
                                  if (entry.gridPosition != null && entry.gridPosition! > 1) {
                                    entry.gridPosition = entry.gridPosition! - 1;
                                  }
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                            SizedBox(
                              width: 30,
                              child: Text(
                                entry.gridPosition?.toString() ?? '-',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.white, size: 18),
                              onPressed: () {
                                setState(() {
                                  entry.gridPosition = (entry.gridPosition ?? 0) + 1;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Second row: Status checkbox | Team dropdown
                    Row(
                      children: [
                        const SizedBox(width: 30), // Align with position above
                        // Status checkbox with label
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: entry.status != null,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    entry.status = 'DNF';
                                  } else {
                                    entry.status = null;
                                  }
                                });
                              },
                              activeColor: widget.league.themeColor,
                            ),
                            if (entry.status != null)
                              SizedBox(
                                width: 70,
                                child: DropdownButton<String>(
                                  value: entry.status,
                                  dropdownColor: const Color(0xFF3A3A3A),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  underline: const SizedBox(),
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(value: 'DNF', child: Text('DNF')),
                                    DropdownMenuItem(value: 'DNS', child: Text('DNS')),
                                    DropdownMenuItem(value: 'DSQ', child: Text('DSQ')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      entry.status = value;
                                    });
                                  },
                                ),
                              )
                            else
                              const Text(
                                'OUT',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Team dropdown
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: DropdownButtonFormField<String>(
                              value: entry.teamName,
                              dropdownColor: const Color(0xFF3A3A3A),
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              hint: const Text(
                                'Select team',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              items: _allDrivers
                                  .where((d) => d.teamName != null)
                                  .map((d) => d.teamName!)
                                  .toSet()
                                  .map((team) {
                                return DropdownMenuItem<String>(
                                  value: team,
                                  child: Text(team),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  entry.teamName = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Third row: Time input
                    Row(
                      children: [
                        const SizedBox(width: 30), // Align with position above
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: TextFormField(
                              key: ValueKey('time_${entry.driverId}_$index'),
                              initialValue: entry.raceTimeMillis != null
                                  ? (index == 0
                                      ? _formatAbsoluteTime(entry.raceTimeMillis!)
                                      : (_resultEntries.isNotEmpty && _resultEntries[0].raceTimeMillis != null
                                          ? _formatGapTime(entry.raceTimeMillis! - _resultEntries[0].raceTimeMillis!)
                                          : _formatAbsoluteTime(entry.raceTimeMillis!)))
                                  : '',
                              enabled: entry.status == null,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                                letterSpacing: 1.2,
                              ),
                              decoration: InputDecoration(
                                labelText: index == 0 ? 'Time (H:MM:SS.mmm)' : 'Gap (+MM:SS.mmm)',
                                labelStyle: TextStyle(
                                  color: entry.status == null ? widget.league.themeColor.withValues(alpha: 0.7) : Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                                hintText: index == 0 ? 'e.g., 1:24:35.123' : 'e.g., +25:44.389',
                                hintStyle: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                filled: true,
                                fillColor: entry.status == null ? Colors.black87 : Colors.grey.shade900,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade800, width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: widget.league.themeColor.withValues(alpha: 0.9), width: 2),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade900, width: 1),
                                ),
                                isDense: true,
                              ),
                              inputFormatters: [
                                index == 0 ? _TimeInputFormatter() : _GapTimeInputFormatter()
                              ],
                              onChanged: (value) {
                                setState(() {
                                  if (index == 0) {
                                    // 1st place: Parse absolute time directly
                                    entry.raceTimeMillis = _parseRaceTimeMillis(value);
                                  } else {
                                    // 2nd place onwards: Parse gap time and add to leader's time
                                    final gapMs = _parseRaceTimeMillis(value);
                                    if (gapMs != null && _resultEntries.isNotEmpty && _resultEntries[0].raceTimeMillis != null) {
                                      entry.raceTimeMillis = _resultEntries[0].raceTimeMillis! + gapMs;
                                    } else {
                                      entry.raceTimeMillis = gapMs;
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackInfoSection() {
    final flagEmoji = widget.event.flagEmoji;
    final trackName = _expandedTrackName(widget.event.name);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade900, Colors.black87],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.league.themeColor.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.league.themeColor.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFlagIcon(flagEmoji),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              trackName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlagIcon(String? flagEmoji) {
    final assetPath = _resolveFlagAsset(flagEmoji, widget.event.name);
    if (assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SvgPicture.asset(
          assetPath,
          width: 54,
          height: 36,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => _fallbackFlag(flagEmoji),
        ),
      );
    }

    return _fallbackFlag(flagEmoji);
  }

  Widget _fallbackFlag(String? flagEmoji) {
    return Container(
      width: 54,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.white24,
          width: 1,
        ),
      ),
      child: Text(
        flagEmoji ?? '🏁',
        style: const TextStyle(fontSize: 22),
      ),
    );
  }

  String _expandedTrackName(String name) {
    // Replace trailing "GP" with "Grand Prix" for display
    final trimmed = name.trim();
    final lower = trimmed.toLowerCase();
    if (lower.endsWith(' gp')) {
      return '${trimmed.substring(0, trimmed.length - 2).trim()} Grand Prix';
    }
    return trimmed;
  }

  String? _countryCodeFromFlagEmoji(String emoji) {
    if (emoji.runes.length != 2) return null;
    final runes = emoji.runes.toList();
    const base = 0x1F1E6;
    final codeUnits = [
      runes[0] - base + 65,
      runes[1] - base + 65,
    ];
    if (codeUnits.any((u) => u < 65 || u > 90)) return null;
    return String.fromCharCodes(codeUnits);
  }

  String? _resolveFlagAsset(String? flagEmoji, String trackName) {
    final codeFromEmoji =
        flagEmoji != null ? _countryCodeFromFlagEmoji(flagEmoji) : null;
    if (codeFromEmoji != null) {
      return 'assets/flags/${codeFromEmoji.toLowerCase()}.svg';
    }

    final codeFromLetters = _countryCodeFromLetters(flagEmoji);
    if (codeFromLetters != null) {
      return 'assets/flags/${codeFromLetters.toLowerCase()}.svg';
    }

    final codeFromTrack = _countryCodeFromTrackName(trackName);
    if (codeFromTrack != null) {
      return 'assets/flags/${codeFromTrack.toLowerCase()}.svg';
    }

    return null;
  }

  String? _countryCodeFromLetters(String? value) {
    if (value == null) return null;
    final letters = value.replaceAll(RegExp('[^A-Za-z]'), '').toUpperCase();
    if (letters.length >= 2) {
      return letters.substring(letters.length - 2);
    }
    return null;
  }

  String? _countryCodeFromTrackName(String name) {
    final lower = name.toLowerCase();
    for (final entry in _trackCountryMap.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  static const Map<String, String> _trackCountryMap = {
    'bahrain': 'BH',
    'saudi': 'SA',
    'jeddah': 'SA',
    'australia': 'AU',
    'melbourne': 'AU',
    'china': 'CN',
    'shanghai': 'CN',
    'japan': 'JP',
    'suzuka': 'JP',
    'miami': 'US',
    'americas': 'US',
    'cota': 'US',
    'vegas': 'US',
    'austin': 'US',
    'italy': 'IT',
    'imola': 'IT',
    'monza': 'IT',
    'monaco': 'MC',
    'spain': 'ES',
    'catalunya': 'ES',
    'canada': 'CA',
    'austria': 'AT',
    'silverstone': 'GB',
    'britain': 'GB',
    'belgium': 'BE',
    'spa': 'BE',
    'hungary': 'HU',
    'zandvoort': 'NL',
    'netherlands': 'NL',
    'baku': 'AZ',
    'azerbaijan': 'AZ',
    'singapore': 'SG',
    'qatar': 'QA',
    'abu dhabi': 'AE',
    'yas marina': 'AE',
    'brazil': 'BR',
    'interlagos': 'BR',
    'mexico': 'MX',
    'lusail': 'QA',
    'france': 'FR',
    'usa': 'US',
  };

  Widget _buildQualifyingAndFastestLapSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade900,
            Colors.black87,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.league.themeColor.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.league.themeColor.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: widget.league.themeColor.withValues(alpha: 0.9),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'QUALIFYING & FASTEST LAP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Pole lap time
              Expanded(
                child: TextField(
                  controller: _poleLapTimeController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                  ),
                  decoration: InputDecoration(
                    labelText: 'POLE LAP TIME',
                    labelStyle: TextStyle(
                      color: widget.league.themeColor.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                    hintText: 'e.g., 1:14.123',
                    hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: Colors.black87,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade800, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: widget.league.themeColor.withValues(alpha: 0.9), width: 2),
                    ),
                    isDense: true,
                  ),
                  inputFormatters: [_TimeInputFormatter()],
                ),
              ),
              const SizedBox(width: 12),
              // Fastest lap time
              Expanded(
                child: TextField(
                  controller: _fastestLapTimeController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                  ),
                  decoration: InputDecoration(
                    labelText: 'FASTEST LAP TIME',
                    labelStyle: TextStyle(
                      color: widget.league.themeColor.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                    hintText: 'e.g., 1:15.456',
                    hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: Colors.black87,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade800, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: widget.league.themeColor.withValues(alpha: 0.9), width: 2),
                    ),
                    isDense: true,
                  ),
                  inputFormatters: [_TimeInputFormatter()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Fastest lap driver dropdown
          DropdownButtonFormField<String>(
            value: _selectedFastestLapDriverId,
            dropdownColor: Colors.grey.shade900,
            decoration: InputDecoration(
              labelText: 'FASTEST LAP DRIVER',
              labelStyle: TextStyle(
                color: widget.league.themeColor.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: Colors.black87,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade800, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.league.themeColor.withValues(alpha: 0.9), width: 2),
              ),
              isDense: true,
            ),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            hint: Text(
              'Select driver',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            items: _allDrivers.map((d) {
              return DropdownMenuItem<String>(
                value: d.id,
                child: Text(d.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedFastestLapDriverId = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPenaltySection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade900, Colors.black87],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.league.themeColor.withValues(alpha: 0.6), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clickable section header
          InkWell(
            onTap: () {
              setState(() {
                _isPenaltySectionExpanded = !_isPenaltySectionExpanded;
              });
            },
            child: Row(
              children: [
                Icon(Icons.gavel, color: widget.league.themeColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'PENALTIES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Icon(
                  _isPenaltySectionExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: widget.league.themeColor,
                  size: 24,
                ),
              ],
            ),
          ),
          // Conditionally show content when expanded
          if (_isPenaltySectionExpanded) ...[
            const SizedBox(height: 12),
            // Header row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: const [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Driver',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 58,
                    child: Text(
                      'Time Pen (s)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    width: 58,
                    child: Text(
                      'Penalty Pts',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Penalty entries
            ...List.generate(_penaltyEntries.length, (index) {
              return _buildPenaltyRow(index);
            }),
            // Add penalty button
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _penaltyEntries.add(_PenaltyEntry());
                });
              },
              icon: Icon(Icons.add, color: widget.league.themeColor),
              label: Text(
                'Add Penalty',
                style: TextStyle(color: widget.league.themeColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPenaltyRow(int index) {
    final penalty = _penaltyEntries[index];

    return InkWell(
      onLongPress: () async {
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete Penalty'),
              content: const Text('Are you sure you want to delete this penalty?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );

        if (shouldDelete == true) {
          setState(() {
            _penaltyEntries.removeAt(index);
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Driver dropdown
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                value: penalty.driverId,
                dropdownColor: Colors.grey.shade900,
                style: const TextStyle(fontSize: 12, color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade900,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                hint: const Text('Select driver', style: TextStyle(fontSize: 12, color: Colors.white70)),
                items: _allDrivers.map((d) {
                  return DropdownMenuItem<String>(
                    value: d.id,
                    child: Text(d.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    penalty.driverId = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            // Time penalty (seconds)
            SizedBox(
              width: 58,
              child: TextFormField(
                initialValue: penalty.timePenaltySeconds?.toString() ?? '',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade900,
                  hintText: '0',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  setState(() {
                    penalty.timePenaltySeconds = value.isEmpty ? null : int.tryParse(value);
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            // Penalty points
            SizedBox(
              width: 58,
              child: TextFormField(
                initialValue: penalty.penaltyPoints?.toString() ?? '',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade900,
                  hintText: '0',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  setState(() {
                    penalty.penaltyPoints = value.isEmpty ? null : int.tryParse(value);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
