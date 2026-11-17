class HomeDashboardData {
  final String name;
  final String lastName;
  final String email;
  final String? photoUrl;
  final bool? inscriptionPaid;

  const HomeDashboardData({
    required this.name,
    required this.lastName,
    required this.email,
    required this.photoUrl,
    required this.inscriptionPaid,
  });

  factory HomeDashboardData.fromFirestore({
    required Map<String, dynamic> client,
    Map<String, dynamic>? member,
  }) {
    return HomeDashboardData(
      name: _readRequiredString(client, 'name'),
      lastName: _readRequiredString(client, 'lastName'),
      email: _readRequiredString(client, 'email'),
      photoUrl: member == null ? null : _readOptionalString(member, 'photoUrl'),
      inscriptionPaid: member == null
          ? null
          : _readRequiredBool(member, 'inscriptionPaid', 'inscriptionPayed'),
    );
  }

  static String _readRequiredString(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value is! String) {
      throw FormatException('El campo "$field" debe ser texto.');
    }
    return value;
  }

  static String? _readOptionalString(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('El campo "$field" debe ser texto.');
    }
    return value;
  }

  static bool _readRequiredBool(
    Map<String, dynamic> data,
    String field,
    String legacyField,
  ) {
    final value = data[field] ?? data[legacyField];
    if (value is! bool) {
      throw FormatException('El campo "$field" debe ser booleano.');
    }
    return value;
  }
}
