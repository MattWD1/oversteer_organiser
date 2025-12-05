import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/driver.dart';
import '../repositories/driver_repository.dart';

class SessionPage extends StatefulWidget {
  final Event event;
  final DriverRepository driverRepository;

  const SessionPage({
    super.key,
    required this.event,
    required this.driverRepository,
  });

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  bool _loading = true;
  String? _loadError;
  final List<_DriverResult> _results = [];
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    try {
      final List<Driver> drivers =
          await widget.driverRepository.getDriversForEvent(widget.event.id);

      setState(() {
        _results.clear();
        _results.addAll(
          drivers.map(
            (d) => _DriverResult(
              driverId: d.id,
              driverName: d.displayName,
            ),
          ),
        );
        _loading = false;
        _loadError = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  void _saveResults() {
    final missing = _results.where((r) => r.finishPosition == null).toList();
    if (missing.isNotEmpty) {
      setState(() {
        _validationMessage =
            'Please enter a finish position for all drivers before saving.';
      });
      return;
    }

    final positions = _results.map((r) => r.finishPosition!).toList();
    final uniquePositions = positions.toSet();
    if (uniquePositions.length != positions.length) {
      setState(() {
        _validationMessage =
            'Duplicate finish positions detected. Each driver must have a unique finish position.';
      });
      return;
    }

    setState(() {
      _validationMessage = null;
    });

    for (final r in _results) {
      // ignore: avoid_print
      print(
        '${r.driverName} (id=${r.driverId}): grid=${r.gridPosition}, finish=${r.finishPosition}',
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Results collected (not yet saved to database).'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_loadError != null) {
      body = Center(child: Text('Error loading drivers: $_loadError'));
    } else if (_results.isEmpty) {
      body = const Center(child: Text('No drivers found for this session.'));
    } else {
      body = Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Enter grid and finish positions for this session.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          if (_validationMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                _validationMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];

                return ListTile(
                  title: Text(result.driverName),
                  subtitle: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Grid',
                          ),
                          onChanged: (value) {
                            setState(() {
                              result.gridPosition =
                                  int.tryParse(value.trim());
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 110,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Finish',
                          ),
                          onChanged: (value) {
                            setState(() {
                              result.finishPosition =
                                  int.tryParse(value.trim());
                            });
                          },
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
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveResults,
                child: const Text('Save (console only for now)'),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.name),
      ),
      body: body,
    );
  }
}

class _DriverResult {
  final String driverId;
  final String driverName;
  int? gridPosition;
  int? finishPosition;

  _DriverResult({
    required this.driverId,
    required this.driverName,
  });
}
