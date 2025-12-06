class ValidationIssue {
  final String id;
  final String eventId;
  final String? driverId;
  final String code;      // e.g. MISSING_GRID, DUPLICATE_FINISH
  final String message;   // human-readable
  final DateTime createdAt;
  final bool isResolved;

  ValidationIssue({
    required this.id,
    required this.eventId,
    this.driverId,
    required this.code,
    required this.message,
    required this.createdAt,
    this.isResolved = false,
  });

  ValidationIssue copyWith({
    bool? isResolved,
  }) {
    return ValidationIssue(
      id: id,
      eventId: eventId,
      driverId: driverId,
      code: code,
      message: message,
      createdAt: createdAt,
      isResolved: isResolved ?? this.isResolved,
    );
  }
}
