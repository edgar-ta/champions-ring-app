import 'package:champions_ring_app/core/models/core_date.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoreMember {
  final String uid;
  final CoreDate birthDate;
  final String phone;
  final String? photoUrl;
  final bool legalDataAreTheirs;
  final bool inscriptionPayed;

  final DocumentReference<Map<String, dynamic>>? membershipPlanRef;
  final DocumentReference<Map<String, dynamic>>? latestRenewalRef;

  final String? guardianName;
  final String? guardianPhone;
  final String? guardianRelationship;
  final String? curpUrl;
  final bool? curpValidated;

  final String ineBackUrl;
  final bool ineBackValidated;
  final String ineFrontUrl;
  final bool ineFrontValidated;

  final String? waiverAgreementUrl;
  final bool? waiverAgreementValidated;

  final CoreDate creationDate;
  final CoreDate? deletionDate;

  const CoreMember({
    required this.uid,
    required this.birthDate,
    required this.phone,
    this.photoUrl,
    required this.legalDataAreTheirs,
    required this.inscriptionPayed,
    this.membershipPlanRef,
    this.latestRenewalRef,
    this.guardianName,
    this.guardianPhone,
    this.guardianRelationship,
    this.curpUrl,
    this.curpValidated,
    required this.ineBackUrl,
    required this.ineBackValidated,
    required this.ineFrontUrl,
    required this.ineFrontValidated,
    this.waiverAgreementUrl,
    this.waiverAgreementValidated,
    required this.creationDate,
    this.deletionDate,
  });

  Map<String, dynamic> toFirebaseMap() {
    return {
      'uid': uid,
      'birthDate': birthDate.toFirebaseValue(),
      'phone': phone,
      'legalDataAreTheirs': legalDataAreTheirs,
      'inscriptionPayed': inscriptionPayed,
      'ineBackUrl': ineBackUrl,
      'ineBackValidated': ineBackValidated,
      'ineFrontUrl': ineFrontUrl,
      'ineFrontValidated': ineFrontValidated,
      'creationDate': creationDate.toFirebaseValue(),

      if (photoUrl != null) 'photoUrl': photoUrl,
      if (membershipPlanRef != null) 'membershipPlanRef': membershipPlanRef,
      if (latestRenewalRef != null) 'latestRenewalRef': latestRenewalRef,
      if (guardianName != null) 'guardianName': guardianName,
      if (guardianPhone != null) 'guardianPhone': guardianPhone,
      if (guardianRelationship != null)
        'guardianRelationship': guardianRelationship,
      if (curpUrl != null) 'curpUrl': curpUrl,
      if (curpValidated != null) 'curpValidated': curpValidated,
      if (waiverAgreementUrl != null) 'waiverAgreementUrl': waiverAgreementUrl,
      if (waiverAgreementValidated != null)
        'waiverAgreementValidated': waiverAgreementValidated,
      if (deletionDate != null) 'deletionDate': deletionDate!.toFirebaseValue(),
    };
  }
}
