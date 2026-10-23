import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _rojo = Color(0xFFEA3A3F);
const Color _fondo = Color(0xFFF5F5F5);
const Color _texto = Color(0xFF222222);
const Color _gris = Color(0xFF6B6B6B);

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Inicia sesión para consultar tus documentos.'),
      );
    }

    final userDocument = FirebaseFirestore.instanceFor(
      app: FirebaseAuth.instance.app,
      databaseId: 'default',
    ).collection('users').doc(user.uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDocument.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('No se pudieron cargar tus documentos.'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data();

        if (data == null) {
          return const Center(
            child: Text('No se encontró la información de tu cuenta.'),
          );
        }

        final documents = <_OfficialDocument>[
          _OfficialDocument(
            title: 'INE — Parte frontal',
            description: 'Parte delantera de tu identificación.',
            url: data['ine_front_url']?.toString() ?? '',
            icon: Icons.badge_outlined,
          ),
          _OfficialDocument(
            title: 'INE — Parte trasera',
            description: 'Parte trasera de tu identificación.',
            url: data['ine_back_url']?.toString() ?? '',
            icon: Icons.badge_outlined,
          ),
          _OfficialDocument(
            title: 'CURP',
            description: 'Documento de identificación CURP.',
            url: data['curp_url']?.toString() ?? '',
            icon: Icons.description_outlined,
          ),
          _OfficialDocument(
            title: 'Responsiva firmada',
            description: 'Firma registrada durante tu inscripción.',
            url: data['signature_url']?.toString() ?? '',
            icon: Icons.draw_outlined,
          ),
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Documentos oficiales',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _texto,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Consulta los documentos registrados en tu cuenta.',
                    style: TextStyle(color: _gris, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  ...documents.map(
                    (document) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _DocumentCard(document: document),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OfficialDocument {
  final String title;
  final String description;
  final String url;
  final IconData icon;

  const _OfficialDocument({
    required this.title,
    required this.description,
    required this.url,
    required this.icon,
  });
}

class _DocumentCard extends StatelessWidget {
  final _OfficialDocument document;

  const _DocumentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    final available = document.url.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(document.icon, color: _rojo, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: _texto,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  available ? document.description : 'Documento no disponible.',
                  style: const TextStyle(
                    color: _gris,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                if (available) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          _showPreview(context, document);
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('Ver documento'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _openExternal(context, document.url);
                        },
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Abrir externamente'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPreview(BuildContext context, _OfficialDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DocumentPreviewScreen(document: document),
      ),
    );
  }

  Future<void> _openExternal(BuildContext context, String value) async {
    final uri = Uri.tryParse(value);

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El enlace del documento no es válido.')),
      );
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el documento externamente.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocurrió un error al abrir el documento.'),
          ),
        );
      }
    }
  }
}

class _DocumentPreviewScreen extends StatelessWidget {
  final _OfficialDocument document;

  const _DocumentPreviewScreen({required this.document});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(document.url);
    final isValidUrl =
        uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'https' || uri.scheme == 'http');

    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        title: Text(document.title),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Abrir externamente',
            icon: const Icon(Icons.open_in_new),
            onPressed: isValidUrl ? () => _openExternal(context, uri) : null,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: isValidUrl
                ? _buildPreview(uri)
                : const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'El enlace de este documento no es válido.',
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(Uri uri) {
    final path = uri.path.toLowerCase();

    if (path.endsWith('.pdf')) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Este documento es un PDF y no se puede mostrar '
          'directamente con el visor de imágenes.\n\n'
          'Utiliza el botón superior para abrirlo externamente.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Image.network(
      document.url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }

        return const Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No se pudo mostrar la vista previa.\n\n'
            'Puedes intentar abrir el documento externamente.',
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Future<void> _openExternal(BuildContext context, Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el documento.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocurrió un error al abrir el documento.'),
          ),
        );
      }
    }
  }
}
