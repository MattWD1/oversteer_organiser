import 'package:flutter/material.dart';
import '../models/event.dart';

class SessionPage extends StatefulWidget {
  final Event event;

  const SessionPage({
    super.key,
    required this.event,
  });

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  // Dummy drivers for now – later this will come from your DB / repositories
  final List<_DriverResult> _results = [
    _DriverResult(driverName: 'Driver 1'),
    _DriverResult(driverName: 'Driver 2'),
    _DriverResult(driverName: 'Driver 3'),
    _DriverResult(driverName: 'Driver 4'),
    _DriverResult(driverName: 'Driver 5'),
  ];

  String? _validationMessage;

  void _saveResults() {
    // 1) Check all finish positions filled
    final missing = _results.where((r) => r.finishPosition == null).toList();
    if (missing.isNotEmpty) {
      setState(() {
        _validationMessage =
            'Please enter a finish position for all drivers before saving.';
      });
      return;
    }

    // 2) Check finish positions are unique
    final positions = _results.map((r) => r.finishPosition!).toList();
    final uniquePositions = positions.toSet();
    if (uniquePositions.length != positions.length) {
      setState(() {
        _validationMessage =
            'Duplicate finish positions detected. Each driver must have a unique finish position.';
      });
      return;
    }

    // Passed basic checks
    setState(() {
      _validationMessage = null;
    });

    // For now just print to console + snackbar
    for (final r in _results) {
      // ignore: avoid_print
      print(
        '${r.driverName}: grid=${r.gridPosition}, finish=${r.finishPosition}',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.name),
      ),
      body: Column(
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
      ),
    );
  }
}

class _DriverResult {
  final String driverName;
  int? gridPosition;
  int? finishPosition;

  _DriverResult({
    required this.driverName,
  });
}
