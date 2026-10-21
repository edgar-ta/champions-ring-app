import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color _red = Color(0xFFEA3A3F);
const Color _background = Color(0xFFF5F5F5);
const Color _grey = Color(0xFF6B6B6B);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instanceFor(
        app: FirebaseAuth.instance.app,
        databaseId: "default",
      ).collection('users');

  bool _loading = true;
  bool _saving = false;
  bool _initialized = false;

  String? _documentId;
  String? _loadError;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = _uid;

    if (uid == null) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError = 'No hay una sesión iniciada.';
      });
      return;
    }

    try {
      // Primero busca el documento cuyo ID sea el UID.
      final directDocument = await _users.doc(uid).get();

      if (directDocument.exists) {
        _setProfile(directDocument.id, directDocument.data() ?? {});
        return;
      }

      // Si no existe, busca el campo uid dentro de la colección.
      final matchingDocuments = await _users
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (matchingDocuments.docs.isNotEmpty) {
        final document = matchingDocuments.docs.first;
        _setProfile(document.id, document.data());
        return;
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError =
            'No se encontró un perfil asociado a esta cuenta. '
            'Comprueba el UID de Firebase Authentication y el documento '
            'guardado en Firestore.';
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError = error.code == 'permission-denied'
            ? 'No tienes permisos para consultar el perfil en Firebase.'
            : 'No se pudo consultar el perfil. Error: ${error.code}';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError = 'Ocurrió un error al cargar el perfil: $error';
      });
    }
  }

  void _setProfile(String documentId, Map<String, dynamic> data) {
    if (!mounted) return;

    setState(() {
      _documentId = documentId;
      _nameController.text = data['name']?.toString() ?? '';
      _lastNameController.text = data['last_name']?.toString() ?? '';
      _phoneController.text = data['phone']?.toString() ?? '';

      _initialized = true;
      _loading = false;
      _loadError = null;
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final documentId = _documentId;

    if (documentId == null) {
      _showMessage('No se identificó el documento del perfil.');
      return;
    }

    setState(() => _saving = true);

    try {
      await _users.doc(documentId).update({
        'name': _nameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      if (!mounted) return;

      _showMessage('Tus datos se actualizaron correctamente.', success: true);
    } on FirebaseException catch (error) {
      if (!mounted) return;

      _showMessage(
        error.code == 'permission-denied'
            ? 'No tienes permiso para actualizar tus datos.'
            : 'No se pudieron guardar los cambios. Error: ${error.code}',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Ocurrió un error al guardar los cambios.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? const Color(0xFF20864B) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: _background,
        child: Center(child: CircularProgressIndicator(color: _red)),
      );
    }

    if (_loadError != null || !_initialized) {
      return ColoredBox(
        color: _background,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_search_outlined,
                    size: 48,
                    color: _red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No se pudo cargar tu perfil',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _loadError ?? 'No se encontró la información del usuario.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _grey, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _loading = true;
                        _loadError = null;
                      });
                      _loadProfile();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Volver a intentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    'UID de sesión: ${_uid ?? "No disponible"}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: _grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      color: _background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mi perfil',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Consulta y actualiza tus datos personales.',
                  style: TextStyle(color: _grey, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_outline, color: _red, size: 26),
                            SizedBox(width: 10),
                            Text(
                              'Información personal',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildField(
                          label: 'Nombre(s)',
                          controller: _nameController,
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 18),
                        _buildField(
                          label: 'Apellidos',
                          controller: _lastNameController,
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 18),
                        _buildField(
                          label: 'Teléfono',
                          controller: _phoneController,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _saving ? 'Guardando...' : 'GUARDAR CAMBIOS',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4F4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD6D8)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: _red),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'El correo electrónico, la fecha de nacimiento '
                          'y los documentos oficiales no se modifican '
                          'desde este formulario.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: _grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: keyboardType == TextInputType.text
              ? TextCapitalization.words
              : TextCapitalization.none,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _grey, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE3E3E3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE3E3E3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _red, width: 1.5),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Este campo es obligatorio.';
            }
            return null;
          },
        ),
      ],
    );
  }
}
