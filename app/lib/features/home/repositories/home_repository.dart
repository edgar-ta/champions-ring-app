import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_instance.dart';
import '../models/home_dashboard_data.dart';

class HomeRepository {
  final FirebaseFirestore _db;

  HomeRepository({FirebaseFirestore? db})
    : _db = db ?? FirestoreInstance.instance;

  Stream<HomeDashboardData?> watchDashboard(String uid) {
    final clientDocument = _db.collection('clients').doc(uid);
    final memberDocument = _db.collection('members').doc(uid);

    return Stream<HomeDashboardData?>.multi((controller) {
      DocumentSnapshot<Map<String, dynamic>>? clientSnapshot;
      DocumentSnapshot<Map<String, dynamic>>? memberSnapshot;
      var clientLoaded = false;
      var memberLoaded = false;

      void emitDashboard() {
        if (!clientLoaded || !memberLoaded) return;

        final client = clientSnapshot?.data();
        if (client == null || client['deletionDate'] != null) {
          controller.add(null);
          return;
        }

        final member = memberSnapshot?.data();
        final activeMember = member == null || member['deletionDate'] != null
            ? null
            : member;

        try {
          controller.add(
            HomeDashboardData.fromFirestore(
              client: client,
              member: activeMember,
            ),
          );
        } on Object catch (error, stackTrace) {
          controller.addError(error, stackTrace);
        }
      }

      final clientSubscription = clientDocument.snapshots().listen((snapshot) {
        clientSnapshot = snapshot;
        clientLoaded = true;
        emitDashboard();
      }, onError: controller.addError);
      final memberSubscription = memberDocument.snapshots().listen((snapshot) {
        memberSnapshot = snapshot;
        memberLoaded = true;
        emitDashboard();
      }, onError: controller.addError);

      controller.onCancel = () async {
        await Future.wait([
          clientSubscription.cancel(),
          memberSubscription.cancel(),
        ]);
      };
    });
  }
}
