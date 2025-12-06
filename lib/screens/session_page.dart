import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/driver.dart';
import '../models/session_result.dart';
import '../models/validation_issue.dart';
import '../repositories/driver_repository.dart';
import '../repositories/session_result_repository.dart';
import '../repositories/validation_issue_repository.dart';

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

  late List<Driver> _drivers;
  late Map<String, SessionResult> _resultsByDriverId;
  final Map<String, TextEditingController> _gridControllers = {};
  final Map<String, TextEditingController> _finishControllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1) Get drivers for this event
    final drivers =
        await widget.driverRepository.getDriversForEvent(widget.event.id);

    // 2) Get any previously saved results
    final existingResults =
        widget.sessionResultRepository.getResultsForEvent(widget.event.id);

    final resultMap = <String, SessionResult>{};

    // Initialise base results for every driver
    for (final d in drivers) {
      resultMap[d.id] = SessionResult(
        eventId: widget.event.id,
        driverId: d.id,
      );
    }

    // Merge in any existing saved results
    for (final r in existingResults) {
      if (resultMap.containsKey(r.driverId)) {
        resultMap[r.driverId] = resultMap[r.driverId]!.copyWith(
          gridPosition: r.gridPosition,
          finishPosition: r.finishPosition,
        );
      }
    }

    // Create / refresh controllers
    for (final d in drivers) {
      final res = resultMap[d.id]!;

      _gridControllers[d.id]?.dispose();
      _finishControllers[d.id]?.dispose();

      _gridControllers[d.id] = TextEditingController(
        text: res.gridPosition?.toString() ?? '',
      );
      _finishControllers[d.id] = TextEditingController(
        text: res.finishPosition?.toString() ?? '',
      );
    }

    setState(() {
      _drivers = drivers;
      _resultsByDriverId = resultMap;
      _isLoading = false;
    });
  }

  List<ValidationIssue> _validateResults() {
    final issues = <ValidationIssue>[];
    final now = DateTime.now();

    // 1) Check every driver has both grid and finish
    for (final driver in _drivers) {
      final result = _resultsByDriverId[driver.id];

      if (result == null) {
        issues.add(
          ValidationIssue(
            id: '${widget.event.id}_NO_RESULT_${driver.id}_${now.millisecondsSinceEpoch}',
            eventId: widget.event.id,
            driverId: driver.id,
            code: 'NO_RESULT',
            message: 'No result entered for ${driver.name}.',
            createdAt: now,
          ),
        );
        continue;
      }

      if (result.gridPosition == null) {
        issues.add(
          ValidationIssue(
            id: '${widget.event.id}_MISSING_GRID_${driver.id}_${now.millisecondsSinceEpoch}',
            eventId: widget.event.id,
            driverId: driver.id,
            code: 'MISSING_GRID',
            message: 'Missing GRID position for ${driver.name}.',
            createdAt: now,
          ),
        );
      }

      if (result.finishPosition == null) {
        issues.add(
          ValidationIssue(
            id: '${widget.event.id}_MISSING_FINISH_${driver.id}_${now.millisecondsSinceEpoch}',
            eventId: widget.event.id,
            driverId: driver.id,
            code: 'MISSING_FINISH',
            message: 'Missing FINISH position for ${driver.name}.',
            createdAt: now,
          ),
        );
      }
    }

    // 2) Check for duplicate GRID positions
    final gridMap = <int, List<Driver>>{};
    for (final driver in _drivers) {
      final grid = _resultsByDriverId[driver.id]?.gridPosition;
      if (grid == null) continue;

      gridMap.putIfAbsent(grid, () => []);
      gridMap[grid]!.add(driver);
    }

    gridMap.forEach((position, driversWithSame) {
      if (driversWithSame.length > 1) {
        final names = driversWithSame.map((d) => d.name).join(', ');
        issues.add(
          ValidationIssue(
            id: '${widget.event.id}_DUPLICATE_GRID_${position}_${now.millisecondsSinceEpoch}',
            eventId: widget.event.id,
            driverId: null,
            code: 'DUPLICATE_GRID',
            message: 'Duplicate GRID position $position for: $names.',
            createdAt: now,
          ),
        );
      }
    });

    // 3) Check for duplicate FINISH positions
    final finishMap = <int, List<Driver>>{};
    for (final driver in _drivers) {
      final finish = _resultsByDriverId[driver.id]?.finishPosition;
      if (finish == null) continue;

      finishMap.putIfAbsent(finish, () => []);
      finishMap[finish]!.add(driver);
    }

    finishMap.forEach((position, driversWithSame) {
      if (driversWithSame.length > 1) {
        final names = driversWithSame.map((d) => d.name).join(', ');
        issues.add(
          ValidationIssue(
            id: '${widget.event.id}_DUPLICATE_FINISH_${position}_${now.millisecondsSinceEpoch}',
            eventId: widget.event.id,
            driverId: null,
            code: 'DUPLICATE_FINISH',
            message: 'Duplicate FINISH position $position for: $names.',
            createdAt: now,
          ),
        );
      }
    });

    // 4) Check FINISH positions are in a sensible range (1..N)
    final maxPosition = _drivers.length;
    for (final driver in _drivers) {
      final finish = _resultsByDriverId[driver.id]?.finishPosition;
      if (finish == null) continue;

      if (finish < 1 || finish > maxPosition) {
        issues.add(
          ValidationIssue(
            id: '${widget.event.id}_INVALID_FINISH_${driver.id}_${now.millisecondsSinceEpoch}',
            eventId: widget.event.id,
            driverId: driver.id,
            code: 'INVALID_FINISH_RANGE',
            message:
                'Finish position for ${driver.name} should be between 1 and $maxPosition.',
            createdAt: now,
          ),
        );
      }
    }

    return issues;
  }

  void _updateGridPosition(String driverId, String value) {
    final parsed = int.tryParse(value);
    setState(() {
      final current = _resultsByDriverId[driverId]!;
      _resultsByDriverId[driverId] =
          current.copyWith(gridPosition: parsed);
    });
  }

  void _updateFinishPosition(String driverId, String value) {
    final parsed = int.tryParse(value);
    setState(() {
      final current = _resultsByDriverId[driverId]!;
      _resultsByDriverId[driverId] =
          current.copyWith(finishPosition: parsed);
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    // Run validation first
    final issues = _validateResults();

    // Save or clear issues in repository
    if (issues.isNotEmpty) {
      widget.validationIssueRepository
          .replaceIssuesForEvent(widget.event.id, issues);
    } else {
      widget.validationIssueRepository.clearIssuesForEvent(widget.event.id);
    }

    if (issues.isNotEmpty) {
      setState(() => _isSaving = false);

      if (mounted) {
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
                        (issue) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('• ${issue.message}'),
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
      }

      // User needs to fix issues and press Save again
      return;
    }

    // If we get here, results are valid → save them
    final results = _resultsByDriverId.values.toList();
    widget.sessionResultRepository
        .saveResultsForEvent(widget.event.id, results);

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session results saved')),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _gridControllers.values) {
      c.dispose();
    }
    for (final c in _finishControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results – ${widget.event.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _drivers.length,
                    itemBuilder: (context, index) {
                      final driver = _drivers[index];

                      final gridController = _gridControllers[driver.id]!;
                      final finishController =
                          _finishControllers[driver.id]!;

                      return ListTile(
                        title: Text(driver.name),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: gridController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Grid',
                                ),
                                onChanged: (value) =>
                                    _updateGridPosition(driver.id, value),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: finishController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Finish',
                                ),
                                onChanged: (value) =>
                                    _updateFinishPosition(driver.id, value),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Results'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
