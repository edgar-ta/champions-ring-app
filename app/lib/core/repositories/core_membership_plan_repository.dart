import 'package:champions_ring_app/core/models/core_date.dart';
import 'package:champions_ring_app/core/models/core_membership_plan.dart';
import 'package:champions_ring_app/core/utils/base_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoreMembershipPlanRepository extends BaseRepository<CoreMembershipPlan> {
  @override
  String get collectionName => 'membership_plans';

  @override
  Future<CoreMembershipPlan> getById(String uid) async {
    final snapshot = await myCollection.doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Core membership plan with id "$uid" was not found.');
    }

    return _fromFirebaseMap(data);
  }

  Future<List<CoreMembershipPlan>> getActiveMembershipPlans() async {
    final snapshot = await myCollection.get();
    return snapshot.docs
        .where((document) => document.data()['deletionDate'] == null)
        .map((document) => _fromFirebaseMap(document.data()))
        .toList(growable: false);
  }

  CoreMembershipPlan _fromFirebaseMap(Map<String, dynamic> data) {
    final creationDate = data['creationDate'] as Timestamp;
    final deletionDate = data['deletionDate'] as Timestamp?;

    return CoreMembershipPlan(
      uid: data['uid'] as String,
      name: data['name'] as String,
      cost: (data['cost'] as num).toDouble(),
      benefits: data['benefits'] as String,
      duration: _durationFromSerialization(data['duration'] as String),
      creationDate: CoreDate.fromTimestamp(creationDate),
      deletionDate: deletionDate == null
          ? null
          : CoreDate.fromTimestamp(deletionDate),
    );
  }

  CoreMembershipPlanDuration _durationFromSerialization(String value) =>
      switch (value) {
        '1d' => CoreMembershipPlanDuration.oneDay,
        '1w' => CoreMembershipPlanDuration.oneWeek,
        '1m' => CoreMembershipPlanDuration.oneMonth,
        _ => throw FormatException(
          'Unknown membership plan duration "$value".',
        ),
      };
}
