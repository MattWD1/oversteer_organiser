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

class _SessionPageState extends State<SessionPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  final List<Driver> _allDrivers = [];
  final List<_ResultEntry> _resultEntries = [];

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
        for (final driver in _allDrivers) {
          _resultEntries.add(_ResultEntry(
            driverId: driver.id,
            teamName: driver.teamName,
            gridPosition: null,
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

  @override
  void dispose() {
    _poleLapTimeController.dispose();
    _fastestLapTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.event.name),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.event.name),
        ),
        body: Center(
          child: Text(_loadError!),
        ),
      );
    }

    final issues =
        widget.validationIssueRepository.getIssuesForEvent(widget.event.id);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.grey.shade900,
              Colors.red.shade900,
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
          IconButton(
            tooltip: 'Save results',
            onPressed: _isSaving ? null : _saveResults,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
          if (_isSaving)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
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
          ],
        ),
      ),
    ),
          ),
        ],
      ),
        ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      key: const ValueKey('header'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(width: 40), // Space for drag handle
          const SizedBox(
            width: 30,
            child: Text(
              'Pos.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
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
          const SizedBox(
            width: 96, // Width for grid +/- buttons
            child: Text(
              'Grid',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
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
                                entry.gridPosition?.toString() ?? '1',
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
                              activeColor: Colors.red,
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
                                  ? _formatAbsoluteTime(entry.raceTimeMillis!)
                                  : '',
                              enabled: entry.status == null,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                                letterSpacing: 1.2,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Time (H:MM:SS.mmm)',
                                labelStyle: TextStyle(
                                  color: entry.status == null ? Colors.red.shade400 : Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                                hintText: 'e.g., 1:24:35.123',
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
                                  borderSide: BorderSide(color: Colors.red.shade600, width: 2),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade900, width: 1),
                                ),
                                isDense: true,
                              ),
                              inputFormatters: [_TimeInputFormatter()],
                              onChanged: (value) {
                                setState(() {
                                  entry.raceTimeMillis = _parseRaceTimeMillis(value);
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
          color: Colors.red.shade800,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withAlpha(76),
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
                color: Colors.red.shade600,
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
                      color: Colors.red.shade400,
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
                      borderSide: BorderSide(color: Colors.red.shade600, width: 2),
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
                      color: Colors.red.shade400,
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
                      borderSide: BorderSide(color: Colors.red.shade600, width: 2),
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
                color: Colors.red.shade400,
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
                borderSide: BorderSide(color: Colors.red.shade600, width: 2),
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
}
