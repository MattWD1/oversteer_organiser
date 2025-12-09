import 'dart:async';

import '../models/driver.dart';

abstract class DriverRepository {
  /// All drivers taking part in a given event.
  Future<List<Driver>> getDriversForEvent(String eventId);

  /// Look up a single driver by ID.
  Future<Driver?> getDriverById(String driverId);
}

class InMemoryDriverRepository implements DriverRepository {
  // Example drivers for testing. Adjust names/teams/numbers as you like.
  final List<Driver> _drivers = const [
    Driver(
      id: 'drv1',
      name: 'Lewis Hamilton',
      teamName: 'Mercedes',
      number: 44,
      nationality: 'British',
    ),
    Driver(
      id: 'drv2',
      name: 'Max Verstappen',
      teamName: 'Red Bull Racing',
      number: 1,
      nationality: 'Dutch',
    ),
    Driver(
      id: 'drv3',
      name: 'Charles Leclerc',
      teamName: 'Scuderia Ferrari',
      number: 16,
      nationality: 'Monégasque',
    ),
    Driver(
      id: 'drv4',
      name: 'Lando Norris',
      teamName: 'McLaren',
      number: 4,
      nationality: 'British',
    ),
  ];

  @override
  Future<List<Driver>> getDriversForEvent(String eventId) async {
    // In a real app, this would filter by eventId/division.
    await Future.delayed(const Duration(milliseconds: 200));
    return _drivers;
  }

  @override
  Future<Driver?> getDriverById(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    for (final d in _drivers) {
      if (d.id == driverId) return d;
    }
    return null;
  }
}
