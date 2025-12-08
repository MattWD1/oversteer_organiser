// lib/models/session_result.dart

class SessionResult {
  final String driverId;

  int? gridPosition;
  int? finishPosition;
  int? raceTimeMillis;

  /// True if this driver set the fastest lap in the event.
  bool hasFastestLap;

  /// The fastest lap time in milliseconds for this driver (if they had FL).
  int? fastestLapMillis;

  /// The pole lap time in milliseconds for this driver if they started P1.
  /// (Only one driver per event should have this set, typically gridPosition == 1).
  int? poleLapMillis;

  SessionResult({
    required this.driverId,
    this.gridPosition,
    this.finishPosition,
    this.raceTimeMillis,
    this.hasFastestLap = false,
    this.fastestLapMillis,
    this.poleLapMillis,
  });

  SessionResult copyWith({
    int? gridPosition,
    int? finishPosition,
    int? raceTimeMillis,
    bool? hasFastestLap,
    int? fastestLapMillis,
    int? poleLapMillis,
  }) {
    return SessionResult(
      driverId: driverId,
      gridPosition: gridPosition ?? this.gridPosition,
      finishPosition: finishPosition ?? this.finishPosition,
      raceTimeMillis: raceTimeMillis ?? this.raceTimeMillis,
      hasFastestLap: hasFastestLap ?? this.hasFastestLap,
      fastestLapMillis: fastestLapMillis ?? this.fastestLapMillis,
      poleLapMillis: poleLapMillis ?? this.poleLapMillis,
    );
  }
}
