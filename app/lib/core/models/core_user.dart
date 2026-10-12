import 'package:cloud_firestore/cloud_firestore.dart';

import 'core_date.dart';

enum CoreUserType { administrator, member, receptionist }

enum CorePaymentMethod { cash, card }

class CoreUser {
  final DateTime birthDate;
  final CoreDate creationDate;
  final CoreDate? deletionDate;
  final String email;
  final String? guardianName;
  final String? guardianPhone;
  final String? guardianRelationship;
  final String ineBackUrl;
  final String ineFrontUrl;
  final String lastName;
  final bool legalDataAreTheirs;
  final int membershipPlanId;
  final String name;
  final CorePaymentMethod paymentMethod;
  final String phone;
  final String photoUrl;
  final bool registrationPayed;
  final String signatureUrl;
  final CoreUserType type;
  final String uid;

  CoreUser({
    required this.birthDate,
    required this.creationDate,
    this.deletionDate,
    required this.email,
    this.guardianName,
    this.guardianPhone,
    this.guardianRelationship,
    required this.ineBackUrl,
    required this.ineFrontUrl,
    required this.lastName,
    required this.legalDataAreTheirs,
    required this.membershipPlanId,
    required this.name,
    required this.paymentMethod,
    required this.phone,
    required this.photoUrl,
    required this.registrationPayed,
    required this.signatureUrl,
    required this.type,
    required this.uid,
  });

  Map<String, dynamic> toFirebaseMap() => {
    'birth_date': Timestamp.fromDate(birthDate),
    'creation_date': _firebaseDate(creationDate),
    'deletion_date': _firebaseDate(deletionDate),
    'email': email,
    'guardian_name': guardianName,
    'guardian_phone': guardianPhone,
    'guardian_relationship': guardianRelationship,
    'ine_back_url': ineBackUrl,
    'ine_front_url': ineFrontUrl,
    'last_name': lastName,
    'legal_data_are_theirs': legalDataAreTheirs,
    'membership_plan_id': membershipPlanId,
    'name': name,
    'payment_method': paymentMethod.name,
    'phone': phone,
    'photo_url': photoUrl,
    'registration_payed': registrationPayed,
    'signature_url': signatureUrl,
    'type': type.name,
    'uid': uid,
  };

  static Object? _firebaseDate(CoreDate? value) => value?.toFirebaseValue();
}
