import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/liability_waiver.dart';
import '../models/user_inscription_data.dart';

/// Genera la carta responsiva en PDF con los datos del alumno y su firma.
Future<Uint8List> buildSignedLiabilityWaiverPdf({
  required UserInscription_PersonalData personal,
  required Uint8List signatureBytes,
  required DateTime signedAt,
}) async {
  final logo = pw.MemoryImage(
    (await rootBundle.load('assets/images/Logo_champions_ring.png'))
        .buffer
        .asUint8List(),
  );
  final signature = pw.MemoryImage(signatureBytes);
  final fullName = '${personal.name} ${personal.lastName}'.trim();
  final isMinor = !personal.isOfLegalAge;
  final signerName = isMinor ? (personal.guardianName ?? '') : fullName;

  final document = pw.Document(
    title: liabilityWaiverTitle,
    author: signerName,
    creator: 'Champions Ring',
  );

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(48),
      build: (context) => [
        pw.Center(child: pw.Image(logo, height: 70)),
        pw.SizedBox(height: 16),
        pw.Center(
          child: pw.Text(
            liabilityWaiverTitle,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 20),
        _field('Alumno', fullName),
        _field('Fecha de nacimiento', _formatDate(personal.birthDate)),
        _field('Correo electrónico', personal.email),
        _field('Teléfono', personal.phone),
        if (isMinor) ...[
          _field('Padre, madre o tutor', personal.guardianName ?? ''),
          _field('Parentesco', personal.guardianRelationship ?? ''),
          _field('Teléfono del tutor', personal.guardianPhone ?? ''),
        ],
        pw.SizedBox(height: 16),
        for (final paragraph in liabilityWaiverParagraphs)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Text(
              paragraph,
              textAlign: pw.TextAlign.justify,
              style: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
            ),
          ),
        pw.SizedBox(height: 24),
        pw.Text(
          'Firmado electrónicamente el ${_formatDateTime(signedAt)}.',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 16),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Image(signature, height: 90),
              pw.Container(width: 240, height: 1, color: PdfColors.black),
              pw.SizedBox(height: 4),
              pw.Text(
                signerName,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                isMinor ? 'Firma del padre, madre o tutor' : 'Firma del alumno',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  return document.save();
}

pw.Widget _field(String label, String value) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 4),
  child: pw.RichText(
    text: pw.TextSpan(
      style: const pw.TextStyle(fontSize: 11),
      children: [
        pw.TextSpan(
          text: '$label: ',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.TextSpan(text: value),
      ],
    ),
  ),
);

String _two(int value) => value.toString().padLeft(2, '0');

String _formatDate(DateTime date) =>
    '${_two(date.day)}/${_two(date.month)}/${date.year}';

String _formatDateTime(DateTime date) =>
    '${_formatDate(date)} a las ${_two(date.hour)}:${_two(date.minute)} hrs';
