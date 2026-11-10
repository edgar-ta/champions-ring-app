import 'package:champions_ring_app/core/models/core_date.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoreRenewal {
  final String uid;
  final CoreDate startDate;
  final CoreDate endDate;

  final DocumentReference<Map<String, dynamic>>? membershipPlanRef;
  final DocumentReference<Map<String, dynamic>> paymentRef;

  final double amount;

  final CoreDate creationDate;
  final CoreDate? deletionDate;

  const CoreRenewal({
    required this.uid,
    required this.startDate,
    required this.endDate,
    this.membershipPlanRef,
    required this.paymentRef,
    required this.amount,
    required this.creationDate,
    this.deletionDate,
  });

  Map<String, dynamic> toFirebaseMap() {
    return {
      'uid': uid,
      'startDate': startDate.toFirebaseValue(),
      'endDate': endDate.toFirebaseValue(),
      'paymentRef': paymentRef,
      'amount': amount,
      'creationDate': creationDate.toFirebaseValue(),

      if (membershipPlanRef != null) 'membershipPlanRef': membershipPlanRef,
      if (deletionDate != null) 'deletionDate': deletionDate!.toFirebaseValue(),
    };
  }
}
