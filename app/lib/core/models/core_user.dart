import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:champions_ring_app/core/utils/firestore_entity.dart';

import 'core_date.dart';

enum CoreUserType { administrator, member, receptionist }

enum CorePaymentMethod { cash, card }

class CoreUser extends FirestoreEntity {
  final DateTime birthDate;
  final CoreDate creationDate;
  final CoreDate? deletionDate;
  final String email;
  final String? guardianName;
  final String? guardianPhone;
  final String? guardianRelationship;
  final String? curpUrl;
  final String ineBackUrl;
  final String ineFrontUrl;
  final String lastName;
  final bool legalDataAreTheirs;
  final int membershipPlanId;
  final String name;
  final CorePaymentMethod? paymentMethod;
  final String phone;
  final String photoUrl;
  final bool registrationPayed;
  final String? signatureUrl;
  final CoreUserType type;
  @override
  final String uid;

  CoreUser({
    required this.birthDate,
    required this.creationDate,
    this.deletionDate,
    required this.email,
    this.guardianName,
    this.guardianPhone,
    this.guardianRelationship,
    this.curpUrl,
    required this.ineBackUrl,
    required this.ineFrontUrl,
    required this.lastName,
    required this.legalDataAreTheirs,
    required this.membershipPlanId,
    required this.name,
    this.paymentMethod,
    required this.phone,
    required this.photoUrl,
    required this.registrationPayed,
    this.signatureUrl,
    required this.type,
    required this.uid,
  });

  @override
  Map<String, dynamic> toFirebaseMap() => {
    'birth_date': Timestamp.fromDate(birthDate),
    'creation_date': _firebaseDate(creationDate),
    'deletion_date': _firebaseDate(deletionDate),
    'email': email,
    'guardian_name': guardianName,
    'guardian_phone': guardianPhone,
    'guardian_relationship': guardianRelationship,
    'curp_url': curpUrl,
    'ine_back_url': ineBackUrl,
    'ine_front_url': ineFrontUrl,
    'last_name': lastName,
    'legal_data_are_theirs': legalDataAreTheirs,
    'membership_plan_id': membershipPlanId,
    'name': name,
    if (paymentMethod != null) 'payment_method': paymentMethod!.name,
    'phone': phone,
    'photo_url': photoUrl,
    'registration_payed': registrationPayed,
    'signature_url': signatureUrl,
    'type': type.name,
    'uid': uid,
  };

  static Object? _firebaseDate(CoreDate? value) => value?.toFirebaseValue();
}
