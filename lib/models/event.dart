class Event {
  final String id;
  final String divisionId;
  final String name;
  final DateTime date;
  final String? flagEmoji;

  const Event({
    required this.id,
    required this.divisionId,
    required this.name,
    required this.date,
    this.flagEmoji,
  });
}
