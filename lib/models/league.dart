class League {
  final String id;
  final String name;
  final String organiserName;
  final DateTime createdAt;
  final String joinCode; // simple invite/join code, e.g. 6 chars

  const League({
    required this.id,
    required this.name,
    required this.organiserName,
    required this.createdAt,
    required this.joinCode,
  });
}
