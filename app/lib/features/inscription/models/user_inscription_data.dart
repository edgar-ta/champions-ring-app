import 'dart:typed_data';

import 'package:champions_ring_app/core/models/core_user.dart'
    show CoreUserType, CorePaymentMethod;

class UserInscription_PersonalData {
  final Uint8List photoBytes;
  final String photoFormat;
  final String name;
  final String lastName;
  final CoreUserType type;
  final DateTime birthDate;
  final String email;
  final String phone;
  final String password; // Solo para Firebase Auth; no se guarda en Firestore.
  final String? guardianName;
  final String? guardianPhone;
  final String? guardianRelationship;

  UserInscription_PersonalData({
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
    this.type = CoreUserType.member,
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

class UserInscription_IdData {
  final Uint8List? ineFrontBytes;
  final String? ineFrontFormat;
  final Uint8List? ineBackBytes;
  final String? ineBackFormat;
  final Uint8List? curpBytes;
  final String? curpFormat;

  UserInscription_IdData({
    this.ineFrontBytes,
    this.ineFrontFormat,
    this.ineBackBytes,
    this.ineBackFormat,
    this.curpBytes,
    this.curpFormat,
  });

  UserInscription_IdData copyWith({
    Uint8List? ineFrontBytes,
    String? ineFrontFormat,
    Uint8List? ineBackBytes,
    String? ineBackFormat,
    Uint8List? curpBytes,
    String? curpFormat,
  }) => UserInscription_IdData(
    ineFrontBytes: ineFrontBytes ?? this.ineFrontBytes,
    ineFrontFormat: ineFrontFormat ?? this.ineFrontFormat,
    ineBackBytes: ineBackBytes ?? this.ineBackBytes,
    ineBackFormat: ineBackFormat ?? this.ineBackFormat,
    curpBytes: curpBytes ?? this.curpBytes,
    curpFormat: curpFormat ?? this.curpFormat,
  );
}

class UserInscription_WaiverAgreementData {
  final Uint8List signatureBytes;

  UserInscription_WaiverAgreementData({required this.signatureBytes});
}

class UserInscription_PlanSelectionData {
  final int membershipPlanId;

  UserInscription_PlanSelectionData({required this.membershipPlanId});
}

class UserInscription_PaymentSelectionData {
  final CorePaymentMethod paymentMethod;

  UserInscription_PaymentSelectionData({required this.paymentMethod});
}

/// Estado agregado del wizard, dividido por paso para poder restaurarlo.
class UserInscriptionData {
  final UserInscription_PersonalData? personalData;
  final UserInscription_IdData? idData;
  final UserInscription_WaiverAgreementData? waiverAgreementData;
  final UserInscription_PlanSelectionData? planSelectionData;
  final UserInscription_PaymentSelectionData? paymentSelectionData;

  const UserInscriptionData({
    this.personalData,
    this.idData,
    this.waiverAgreementData,
    this.planSelectionData,
    this.paymentSelectionData,
  });

  UserInscriptionData copyWith({
    UserInscription_PersonalData? personalData,
    UserInscription_IdData? idData,
    UserInscription_WaiverAgreementData? waiverAgreementData,
    UserInscription_PlanSelectionData? planSelectionData,
    UserInscription_PaymentSelectionData? paymentSelectionData,
    bool clearIdData = false,
    bool clearWaiverAgreementData = false,
    bool clearPlanSelectionData = false,
    bool clearPaymentSelectionData = false,
  }) => UserInscriptionData(
    personalData: personalData ?? this.personalData,
    idData: clearIdData ? null : (idData ?? this.idData),
    waiverAgreementData: clearWaiverAgreementData
        ? null
        : (waiverAgreementData ?? this.waiverAgreementData),
    planSelectionData: clearPlanSelectionData
        ? null
        : (planSelectionData ?? this.planSelectionData),
    paymentSelectionData: clearPaymentSelectionData
        ? null
        : (paymentSelectionData ?? this.paymentSelectionData),
  );

  bool get isOfLegalAge => personalData?.isOfLegalAge ?? true;
}
