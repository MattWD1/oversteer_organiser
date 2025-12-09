// lib/models/driver.dart

/// Core driver model used across the app.
///
/// This already supports future database use:
/// - `id` is the stable identifier
/// - `number`, `nationality` and `teamName` are editable metadata
class Driver {
  final String id;

  String name;
  int? number;
  String? nationality;
  String? teamName;

  Driver({
    required this.id,
    required this.name,
    this.number,
    this.nationality,
    this.teamName,
  });

  /// Helper for creating a modified copy if you prefer immutable-style updates.
  Driver copyWith({
    String? name,
    int? number,
    String? nationality,
    String? teamName,
  }) {
    return Driver(
      id: id,
      name: name ?? this.name,
      number: number ?? this.number,
      nationality: nationality ?? this.nationality,
      teamName: teamName ?? this.teamName,
    );
  }
}
