import '../models/driver.dart';

abstract class DriverRepository {
  Future<List<Driver>> getDriversForEvent(String eventId);
}

class InMemoryDriverRepository implements DriverRepository {
  final List<Driver> _drivers = [
    Driver(
      id: 'drv1',
      displayName: 'L. Hamilton',
      carNumber: 44,
      nationalityCode: 'GBR',
    ),
    Driver(
      id: 'drv2',
      displayName: 'M. Verstappen',
      carNumber: 1,
      nationalityCode: 'NED',
    ),
    Driver(
      id: 'drv3',
      displayName: 'C. Leclerc',
      carNumber: 16,
      nationalityCode: 'MON',
    ),
    Driver(
      id: 'drv4',
      displayName: 'G. Russell',
      carNumber: 63,
      nationalityCode: 'GBR',
    ),
    Driver(
      id: 'drv5',
      displayName: 'L. Norris',
      carNumber: 4,
      nationalityCode: 'GBR',
    ),
  ];

  @override
  Future<List<Driver>> getDriversForEvent(String eventId) async {
    // For now, ignore eventId and return the same dummy grid.
    await Future.delayed(const Duration(milliseconds: 200));
    return _drivers;
  }
}
