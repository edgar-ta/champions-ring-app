import 'package:champions_ring_app/features/home/models/home_dashboard_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeDashboardData.fromFirestore', () {
    final client = {
      'name': 'Ana',
      'lastName': 'López',
      'email': 'ana@example.com',
    };

    test('maps client and member fields from the current schema', () {
      final data = HomeDashboardData.fromFirestore(
        client: client,
        member: {
          'photoUrl': 'https://example.com/photo.jpg',
          'inscriptionPaid': true,
        },
      );

      expect(data.name, 'Ana');
      expect(data.lastName, 'López');
      expect(data.email, 'ana@example.com');
      expect(data.photoUrl, 'https://example.com/photo.jpg');
      expect(data.inscriptionPaid, isTrue);
    });

    test(
      'accepts the former misspelled payment field for existing members',
      () {
        final data = HomeDashboardData.fromFirestore(
          client: client,
          member: {'inscriptionPayed': false},
        );

        expect(data.inscriptionPaid, isFalse);
      },
    );

    test('allows a client without a member document', () {
      final data = HomeDashboardData.fromFirestore(client: client);

      expect(data.photoUrl, isNull);
      expect(data.inscriptionPaid, isNull);
    });
  });
}
