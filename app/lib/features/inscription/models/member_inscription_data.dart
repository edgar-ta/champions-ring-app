import 'dart:typed_data';

import 'package:champions_ring_app/core/models/core_payment.dart'
    show CorePaymentIssuingEntity, CorePaymentType;

class MemberInscription_PreviousInscriptionData {
  final bool previouslySignedIn;

  MemberInscription_PreviousInscriptionData({required this.previouslySignedIn});
}

class MemberInscription_PersonalData {
  final Uint8List photoBytes;
  final String photoFormat;
  final String name;
  final String lastName;
  final DateTime birthDate;
  final String email;
  final String phone;
  final String password; // Solo para Firebase Auth; no se guarda en Firestore.
  final String? guardianName;
  final String? guardianPhone;
  final String? guardianRelationship;

  MemberInscription_PersonalData({
    required this.photoBytes,
    required this.photoFormat,
    required this.name,
    required this.lastName,
    required this.birthDate,
    required this.email,
    required this.phone,
    required this.password,
    this.guardianName,
    this.guardianPhone,
    this.guardianRelationship,
  });

  bool get isOfLegalAge {
    final today = DateTime.now();
    var age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age >= 18;
  }
}

class MemberInscription_IdData {
  final Uint8List? ineFrontBytes;
  final String? ineFrontFormat;
  final Uint8List? ineBackBytes;
  final String? ineBackFormat;
  final Uint8List? curpBytes;
  final String? curpFormat;

  MemberInscription_IdData({
    this.ineFrontBytes,
    this.ineFrontFormat,
    this.ineBackBytes,
    this.ineBackFormat,
    this.curpBytes,
    this.curpFormat,
  });

  MemberInscription_IdData copyWith({
    Uint8List? ineFrontBytes,
    String? ineFrontFormat,
    Uint8List? ineBackBytes,
    String? ineBackFormat,
    Uint8List? curpBytes,
    String? curpFormat,
  }) => MemberInscription_IdData(
    ineFrontBytes: ineFrontBytes ?? this.ineFrontBytes,
    ineFrontFormat: ineFrontFormat ?? this.ineFrontFormat,
    ineBackBytes: ineBackBytes ?? this.ineBackBytes,
    ineBackFormat: ineBackFormat ?? this.ineBackFormat,
    curpBytes: curpBytes ?? this.curpBytes,
    curpFormat: curpFormat ?? this.curpFormat,
  );
}

class MemberInscription_PlanSelectionData {
  final String membershipPlanUid;

  const MemberInscription_PlanSelectionData({required this.membershipPlanUid});
}

class MemberInscription_PaymentSelectionData {
  final CorePaymentType paymentMethod;
  final String? referenceId;
  final CorePaymentIssuingEntity? issuingEntity;
  final String? issuingEntityName;

  MemberInscription_PaymentSelectionData({
    required this.paymentMethod,
    this.referenceId,
    this.issuingEntity,
    this.issuingEntityName,
  });
}

/// Estado agregado del wizard, dividido por paso para poder restaurarlo.
class MemberInscriptionData {
  final MemberInscription_PreviousInscriptionData? previousInscriptionData;
  final MemberInscription_PersonalData? personalData;
  final MemberInscription_IdData? idData;
  final MemberInscription_PlanSelectionData? planSelectionData;
  final MemberInscription_PaymentSelectionData? paymentSelectionData;

  const MemberInscriptionData({
    this.previousInscriptionData,
    this.personalData,
    this.idData,
    this.planSelectionData,
    this.paymentSelectionData,
  });

  MemberInscriptionData copyWith({
    MemberInscription_PreviousInscriptionData? previousInscriptionData,
    MemberInscription_PersonalData? personalData,
    MemberInscription_IdData? idData,
    MemberInscription_PlanSelectionData? planSelectionData,
    MemberInscription_PaymentSelectionData? paymentSelectionData,
    bool clearIdData = false,
    bool clearPlanSelectionData = false,
    bool clearPaymentSelectionData = false,
  }) => MemberInscriptionData(
    previousInscriptionData:
        previousInscriptionData ?? this.previousInscriptionData,
    personalData: personalData ?? this.personalData,
    idData: clearIdData ? null : (idData ?? this.idData),
    planSelectionData: clearPlanSelectionData
        ? null
        : (planSelectionData ?? this.planSelectionData),
    paymentSelectionData: clearPaymentSelectionData
        ? null
        : (paymentSelectionData ?? this.paymentSelectionData),
  );

  bool get isOfLegalAge => personalData?.isOfLegalAge ?? true;
}
