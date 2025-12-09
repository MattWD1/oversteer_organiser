class Driver {
  final String id;
  final String name;

  /// Name of the team this driver races for (e.g. "Ferrari").
  /// Optional so existing flows still work if you haven’t set it.
  final String? teamName;

  /// Optional fields used on the driver profile page.
  final int? number;
  final String? nationality;

  const Driver({
    required this.id,
    required this.name,
    this.teamName,
    this.number,
    this.nationality,
  });
}
