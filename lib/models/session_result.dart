// lib/models/session_result.dart

class SessionResult {
  final String driverId;

  int? gridPosition;
  int? finishPosition;

  /// Base race time in milliseconds from lights out to chequered flag.
  /// The winner should have the smallest raceTimeMillis, and other drivers
  /// have their own full race time (not just the +gap string).
  int? raceTimeMillis;

  SessionResult({
    required this.driverId,
    this.gridPosition,
    this.finishPosition,
    this.raceTimeMillis,
  });
}
