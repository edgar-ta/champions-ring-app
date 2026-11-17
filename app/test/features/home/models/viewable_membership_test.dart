import 'package:champions_ring_app/features/home/models/viewable_membership.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserMembership', () {
    test('is active when a paid renewal has not expired', () {
      final membership = UserMembership(
        hasPaidRenewal: true,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      expect(membership.isActive, isTrue);
      expect(membership.isExpired, isFalse);
    });

    test('is expired when the paid renewal expiration has passed', () {
      final membership = UserMembership(
        hasPaidRenewal: true,
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );

      expect(membership.isActive, isFalse);
      expect(membership.isExpired, isTrue);
    });

    test('is not active without a paid renewal', () {
      const membership = UserMembership(hasPaidRenewal: false, expiresAt: null);

      expect(membership.isActive, isFalse);
      expect(membership.isExpired, isFalse);
    });
  });
}
