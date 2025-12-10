// lib/repositories/driver_repository.dart

import '../models/driver.dart';

/// Repository abstraction for loading drivers.
///
/// Later this will talk to your real database (per league / division / event),
/// but for now it's an in-memory implementation so the rest of the app can be
/// wired and tested.
abstract class DriverRepository {
  /// Returns all drivers that took part in the given event.
  ///
  /// In the in-memory version this ignores [eventId] and just returns a demo
  /// set, but the signature is ready for a real backend.
  Future<List<Driver>> getDriversForEvent(String eventId);

  /// Updates an existing driver's information.
  ///
  /// In the in-memory version this updates the local list,
  /// but in a real implementation this will persist to a database.
  Future<void> updateDriver(Driver driver);
}

class InMemoryDriverRepository implements DriverRepository {
  /// Demo data – shows that number, nationality and teamName are all working.
  final List<Driver> _drivers = [
    Driver(
      id: 'drv1',
      name: 'Lewis Hamilton',
      number: 44,
      nationality: 'British',
      teamName: 'Mercedes',
    ),
    Driver(
      id: 'drv2',
      name: 'Max Verstappen',
      number: 1,
      nationality: 'Dutch',
      teamName: 'Red Bull Racing',
    ),
    Driver(
      id: 'drv3',
      name: 'Charles Leclerc',
      number: 16,
      nationality: 'Monégasque',
      teamName: 'Ferrari',
    ),
    Driver(
      id: 'drv4',
      name: 'Lando Norris',
      number: 4,
      nationality: 'British',
      teamName: 'McLaren',
    ),
  ];

  @override
  Future<List<Driver>> getDriversForEvent(String eventId) async {
    // In a real app, this will filter drivers by event / division / league.
    await Future.delayed(const Duration(milliseconds: 200));

    // Return copies so the caller can safely mutate name/number/nationality
    // in memory (e.g. via DriverProfilePage) without affecting this list.
    return _drivers
        .map(
          (d) => Driver(
            id: d.id,
            name: d.name,
            number: d.number,
            nationality: d.nationality,
            teamName: d.teamName,
          ),
        )
        .toList();
  }

  @override
  Future<void> updateDriver(Driver driver) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // Find and update the driver in the list
    final index = _drivers.indexWhere((d) => d.id == driver.id);
    if (index != -1) {
      _drivers[index] = Driver(
        id: driver.id,
        name: driver.name,
        number: driver.number,
        nationality: driver.nationality,
        teamName: driver.teamName,
      );
    }
  }
}
