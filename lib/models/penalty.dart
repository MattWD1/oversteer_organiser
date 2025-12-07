class Penalty {
  final String id;
  final String eventId;
  final String driverId;
  final String type; // e.g. "Points", "Time", "Grid"
  final int value;   // e.g. -5 for -5 points / -5 seconds / -3 grid positions
  final String reason;
  final DateTime createdAt;

  Penalty({
    required this.id,
    required this.eventId,
    required this.driverId,
    required this.type,
    required this.value,
    required this.reason,
    required this.createdAt,
  });
}
