import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_instance.dart';
import '../models/user_membership.dart';

/// Lecturas en tiempo real para la pantalla de inicio: cuando el webhook de
/// Mercado Pago (o recepción) activa la membresía, la pantalla se actualiza.
class MembershipService {
  final FirebaseFirestore _db;

  MembershipService({FirebaseFirestore? db})
    : _db = db ?? FirestoreInstance.instance;

  /// Emite null si el perfil no existe.
  Stream<UserMembership?> watchMembership(String uid) =>
      _db.collection('users').doc(uid).snapshots().map((doc) {
        final data = doc.data();
        return data == null ? null : UserMembership.fromFirestore(data);
      });

  /// Estado del pago de Mercado Pago en curso ('pending', 'rejected', ...),
  /// o null si no hay ninguno.
  Stream<String?> watchCurrentPaymentStatus(String uid) => _db
      .collection('payments')
      .where('uid', isEqualTo: uid)
      // Sin orderBy para no requerir un índice compuesto; se ordena aquí.
      .snapshots()
      .map((snapshot) => _currentStatus(snapshot.docs));

  static String? _currentStatus(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) return null;
    DateTime fechaDe(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final creado = doc.data()['createdAt'];
      return creado is Timestamp
          ? creado.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0);
    }

    final ordenados = [...docs]
      ..sort((a, b) => fechaDe(b).compareTo(fechaDe(a)));
    final ultimo = ordenados.first.data();
    // Un pago ya procesado activó una membresía anterior (ahora vencida):
    // no cuenta como pago en curso.
    if (ultimo['processed'] == true) return null;
    return ultimo['status'] as String?;
  }
}
