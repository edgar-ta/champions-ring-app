import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'personal_data_form.dart' show kRojo;

typedef PickedDocument = ({Uint8List bytes, String format});

/// Tarjeta para subir un documento. Al elegir la foto muestra una vista
/// previa y el botón cambia a "CAMBIAR FOTO" (la revisión se hace manualmente).
class DocumentInput extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final ValueChanged<PickedDocument> onDocumentPicked;
  final int maxBytes;
  final Uint8List? initialBytes;

  const DocumentInput({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onDocumentPicked,
    this.maxBytes = 20 * 1024 * 1024,
    this.initialBytes,
  });

  @override
  State<DocumentInput> createState() => _DocumentInputState();
}

class _DocumentInputState extends State<DocumentInput> {
  late Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = widget.initialBytes;
  }

  @override
  void didUpdateWidget(covariant DocumentInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialBytes != widget.initialBytes) {
      _bytes = widget.initialBytes;
    }
  }

  Future<void> _pickDocument() async {
    ImageSource? fuente = ImageSource.gallery;

    // En móvil ofrecemos cámara o galería; en web solo el selector de archivos.
    if (!kIsWeb) {
      fuente = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de la galería'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
    }
    if (fuente == null) return;

    final imagen = await ImagePicker().pickImage(
      source: fuente,
      maxWidth: 2000,
      imageQuality: 90,
    );
    if (imagen == null) return;
    final bytes = await imagen.readAsBytes();
    if (!mounted) return;
    if (bytes.length > widget.maxBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El archivo no debe superar ${widget.maxBytes ~/ (1024 * 1024)} MB.')),
      );
      return;
    }
    setState(() => _bytes = bytes);
    final extension = RegExp(r'\.([^.]+)$').firstMatch(imagen.name)?.group(1);
    final format = extension?.toLowerCase() ?? 'jpg';
    widget.onDocumentPicked((bytes: bytes, format: format));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E3E3)),
      ),
      child: Column(
        children: [
          if (_bytes == null)
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBEC),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: kRojo, size: 22),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _bytes!,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            widget.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B6B6B),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _pickDocument,
            style: ElevatedButton.styleFrom(
              backgroundColor: kRojo,
              foregroundColor: Colors.white,
              elevation: 3,
              shadowColor: kRojo.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              _bytes == null ? 'SUBIR O TOMAR FOTO' : 'CAMBIAR FOTO',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
