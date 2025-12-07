// lib/screens/penalties_page.dart

import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/driver.dart';
import '../models/penalty.dart';
import '../repositories/driver_repository.dart';
import '../repositories/penalty_repository.dart';

class PenaltiesPage extends StatefulWidget {
  final Event event;
  final DriverRepository driverRepository;
  final PenaltyRepository penaltyRepository;

  const PenaltiesPage({
    super.key,
    required this.event,
    required this.driverRepository,
    required this.penaltyRepository,
  });

  @override
  State<PenaltiesPage> createState() => _PenaltiesPageState();
}

class _PenaltiesPageState extends State<PenaltiesPage> {
  bool _isLoading = true;
  String? _error;

  List<Driver> _drivers = [];
  List<Penalty> _penalties = [];

  String? _selectedDriverId;
  String _selectedType = 'Points'; // Points / Time / Grid
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final drivers =
          await widget.driverRepository.getDriversForEvent(widget.event.id);
      final penalties =
          widget.penaltyRepository.getPenaltiesForEvent(widget.event.id);

      setState(() {
        _drivers = drivers;
        _penalties = penalties;
        _selectedDriverId = drivers.isNotEmpty ? drivers.first.id : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading penalties: $e';
        _isLoading = false;
      });
    }
  }

  void _addPenalty() {
    if (_selectedDriverId == null) {
      _showSnackBar('Please select a driver.');
      return;
    }

    final rawValue = _valueController.text.trim();
    if (rawValue.isEmpty) {
      _showSnackBar('Please enter a penalty value.');
      return;
    }

    final value = int.tryParse(rawValue);
    if (value == null) {
      _showSnackBar('Penalty value must be a number (e.g. -5).');
      return;
    }

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      _showSnackBar('Please enter a reason for the penalty.');
      return;
    }

    final now = DateTime.now();
    final penaltyId =
        '${widget.event.id}_${_selectedDriverId}_${now.millisecondsSinceEpoch}';

    final penalty = Penalty(
      id: penaltyId,
      eventId: widget.event.id,
      driverId: _selectedDriverId!,
      type: _selectedType,
      value: value,
      reason: reason,
      createdAt: now,
    );

    widget.penaltyRepository.addPenalty(penalty);

    setState(() {
      _penalties =
          widget.penaltyRepository.getPenaltiesForEvent(widget.event.id);
      _valueController.clear();
      _reasonController.clear();
    });

    _showSnackBar('Penalty added.');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  String _formatPenaltyTitle(Penalty p) {
    switch (p.type) {
      case 'Points':
        return 'Points: ${p.value}';
      case 'Time':
        return 'Time: ${p.value} s';
      case 'Grid':
        return 'Grid: ${p.value} positions';
      default:
        return '${p.type}: ${p.value}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Penalties – ${widget.event.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _drivers.isEmpty
                  ? const Center(
                      child: Text('No drivers available for this event.'),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Add penalty',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                // ignore: deprecated_member_use
                                value: _selectedDriverId,
                                decoration: const InputDecoration(
                                  labelText: 'Driver',
                                  border: OutlineInputBorder(),
                                ),
                                items: _drivers
                                    .map(
                                      (d) => DropdownMenuItem(
                                        value: d.id,
                                        child: Text(d.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDriverId = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                // ignore: deprecated_member_use
                                value: _selectedType,
                                decoration: const InputDecoration(
                                  labelText: 'Penalty type',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Points',
                                    child: Text('Points penalty'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Time',
                                    child: Text('Time penalty (seconds)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Grid',
                                    child: Text('Grid drop (positions)'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _selectedType = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _valueController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Value (e.g. -5)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _reasonController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Reason',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _addPenalty,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add penalty'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 0),
                        Expanded(
                          child: _penalties.isEmpty
                              ? const Center(
                                  child: Text('No penalties recorded yet.'),
                                )
                              : ListView.builder(
                                  itemCount: _penalties.length,
                                  itemBuilder: (context, index) {
                                    final p = _penalties[index];
                                    final driver = _drivers.firstWhere(
                                      (d) => d.id == p.driverId,
                                      orElse: () => Driver(
                                        id: p.driverId,
                                        name: 'Unknown driver',
                                      ),
                                    );

                                    return ListTile(
                                      leading: const Icon(
                                        Icons.gavel_outlined,
                                      ),
                                      title: Text(
                                        '${driver.name} – ${_formatPenaltyTitle(p)}',
                                      ),
                                      subtitle: Text(p.reason),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
    );
  }
}
