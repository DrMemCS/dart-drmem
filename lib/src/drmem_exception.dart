class DrMemException implements Exception {
  final String desc;

  const DrMemException(this.desc);

  @override
  String toString() => desc;
}
