class SessionResult {
  final String eventId;
  final String driverId;
  int? gridPosition;
  int? finishPosition;

  SessionResult({
    required this.eventId,
    required this.driverId,
    this.gridPosition,
    this.finishPosition,
  });

  SessionResult copyWith({
    int? gridPosition,
    int? finishPosition,
  }) {
    return SessionResult(
      eventId: eventId,
      driverId: driverId,
      gridPosition: gridPosition ?? this.gridPosition,
      finishPosition: finishPosition ?? this.finishPosition,
    );
  }
}
