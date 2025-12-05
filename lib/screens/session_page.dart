import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/driver.dart';
import '../models/session_result.dart';
import '../repositories/driver_repository.dart';
import '../repositories/session_result_repository.dart';

class SessionPage extends StatefulWidget {
  final Event event;
  final DriverRepository driverRepository;
  final SessionResultRepository sessionResultRepository;

  const SessionPage({
    super.key,
    required this.event,
    required this.driverRepository,
    required this.sessionResultRepository,
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

    for (final d in drivers) {
      resultMap[d.id] = SessionResult(
        eventId: widget.event.id,
        driverId: d.id,
      );
    }

    for (final r in existingResults) {
      if (resultMap.containsKey(r.driverId)) {
        resultMap[r.driverId] = resultMap[r.driverId]!.copyWith(
          gridPosition: r.gridPosition,
          finishPosition: r.finishPosition,
        );
      }
    }

    // Create controllers
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
