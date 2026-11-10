import 'package:champions_ring_app/core/models/core_date.dart';

enum CoreMembershipPlanDuration {
  oneDay('1d'),
  oneWeek('1w'),
  oneMonth('1m');

  final String serialization;

  const CoreMembershipPlanDuration(this.serialization);
}

class CoreMembershipPlan {
  final String uid;
  final String name;
  final double cost;
  final String benefits;
  final CoreMembershipPlanDuration duration;

  final CoreDate creationDate;
  final CoreDate? deletionDate;

  const CoreMembershipPlan({
    required this.uid,
    required this.name,
    required this.cost,
    required this.benefits,
    required this.duration,
    required this.creationDate,
    this.deletionDate,
  });

  Map<String, dynamic> toFirebaseMap() {
    return {
      'uid': uid,
      'cost': cost,
      'benefits': benefits,
      'duration': duration.serialization,
      'creationDate': creationDate.toFirebaseValue(),

      if (deletionDate != null) 'deletionDate': deletionDate!.toFirebaseValue(),
    };
  }
}
