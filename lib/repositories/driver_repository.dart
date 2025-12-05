import '../models/driver.dart';

abstract class DriverRepository {
  Future<List<Driver>> getDriversForEvent(String eventId);
}

class InMemoryDriverRepository implements DriverRepository {
  final List<Driver> _drivers = const [
    Driver(id: 'drv1', name: 'Lewis Hamilton'),
    Driver(id: 'drv2', name: 'Max Verstappen'),
    Driver(id: 'drv3', name: 'Charles Leclerc'),
    Driver(id: 'drv4', name: 'Lando Norris'),
  ];

  @override
  Future<List<Driver>> getDriversForEvent(String eventId) async {
    // In a real app, this would filter by eventId.
    await Future.delayed(const Duration(milliseconds: 200));
    return _drivers;
  }
}
