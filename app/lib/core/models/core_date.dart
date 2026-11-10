import 'package:cloud_firestore/cloud_firestore.dart';

/// Fecha que puede representar un valor listo para Firestore o una fecha local.
class CoreDate {
  final DateTime? dateTime;
  final Timestamp? timestamp;
  final FieldValue? fieldValue;

  const CoreDate._({this.dateTime, this.timestamp, this.fieldValue});

  const CoreDate.fromDateTime(DateTime value) : this._(dateTime: value);

  const CoreDate.fromTimestamp(Timestamp value) : this._(timestamp: value);

  CoreDate.ofWriteTime() : this._(fieldValue: FieldValue.serverTimestamp());

  const CoreDate.ofServerControlledDate() : this._();

  /// Valor que puede agregarse directamente a un mapa de Firestore.
  Object toFirebaseValue() =>
      fieldValue ??
      timestamp ??
      (dateTime != null ? Timestamp.fromDate(dateTime!) : Timestamp.now());
}
