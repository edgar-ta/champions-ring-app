class UserMembership {
  final bool hasPaidRenewal;
  final DateTime? expiresAt;

  const UserMembership({required this.hasPaidRenewal, required this.expiresAt})
    : assert(!hasPaidRenewal || expiresAt != null);

  bool get isActive =>
      hasPaidRenewal && expiresAt != null && expiresAt!.isAfter(DateTime.now());

  bool get isExpired => hasPaidRenewal && !isActive;
}
