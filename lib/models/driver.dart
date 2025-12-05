class Driver {
  final String id;
  final String displayName;
  final int carNumber;
  final String? nationalityCode; // e.g. "GBR", "NED"

  Driver({
    required this.id,
    required this.displayName,
    required this.carNumber,
    this.nationalityCode,
  });
}
