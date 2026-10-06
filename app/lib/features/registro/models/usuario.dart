import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String name;
  final String lastName;
  final String type; // "owner" | "member" | "receptionist"
  final DateTime birthDate;
  final String email;
  final String phone;
  final bool legalDataAreTheirs;
  final String password; // solo para Firebase Auth, NO se guarda en Firestore
  final Uint8List? fotoBytes; // pendiente: aún no se guarda en ningún lado

  Usuario({
    required this.name,
    required this.lastName,
    required this.birthDate,
    required this.email,
    required this.password,
    this.type = 'member',
    this.phone = '',
    this.legalDataAreTheirs = false, // se confirmará en un paso posterior
    this.fotoBytes,
  });

  /// true si ya cumplió 18 años (compara año, mes y día).
  bool get esMayorDeEdad {
    final hoy = DateTime.now();
    var edad = hoy.year - birthDate.year;
    if (hoy.month < birthDate.month ||
        (hoy.month == birthDate.month && hoy.day < birthDate.day)) {
      edad--;
    }
    return edad >= 18;
  }

  /// Mapa para Firestore, con la estructura de la colección "users".
  Map<String, dynamic> toMap(String uid) => {
        'uid': uid,
        'name': name,
        'last_name': lastName,
        'type': type,
        'birth_date': _fechaString(birthDate), // "yyyy-MM-dd"
        'email': email,
        'phone': phone,
        'legal_data_are_theirs': legalDataAreTheirs,
        'signature_url': '',
        'ine_url': '',
        'registration_payed': false,
        'creation_date': FieldValue.serverTimestamp(),
        'deletion_date': null,
      };

  static String _fechaString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}