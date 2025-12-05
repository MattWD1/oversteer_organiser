class Event {
  final String id;
  final String competitionId; // which division/season this event belongs to
  final String name;          // e.g. "Round 1 - Bahrain"
  final int roundNumber;      // 1, 2, 3...

  Event({
    required this.id,
    required this.competitionId,
    required this.name,
    required this.roundNumber,
  });
}
