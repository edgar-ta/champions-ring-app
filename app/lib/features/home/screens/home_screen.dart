import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/firebase/firestore_instance.dart';
import '../../login/screens/login_screen.dart';
import './profile_screen.dart';
import './documents_screen.dart';

const Color _rojo = Color(0xFFEA3A3F);
const Color _fondo = Color(0xFFF5F5F5);
const Color _texto = Color(0xFF222222);
const Color _gris = Color(0xFF6B6B6B);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<_MenuOption> _options = const [
    _MenuOption(
      title: 'Inicio',
      icon: Icons.dashboard_outlined,
      section: 'GENERAL',
    ),
    _MenuOption(
      title: 'Mi perfil',
      icon: Icons.person_outline,
      section: 'MI CUENTA',
    ),
    _MenuOption(
      title: 'Documentos oficiales',
      icon: Icons.folder_outlined,
      section: 'MI CUENTA',
    ),
    _MenuOption(
      title: 'Tienda y equipamiento',
      icon: Icons.shopping_bag_outlined,
      section: 'COMPRAS',
    ),
    _MenuOption(
      title: 'Mis compras',
      icon: Icons.receipt_long_outlined,
      section: 'COMPRAS',
    ),
  ];

  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _seleccionarOpcion(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final userDocument = user == null
        ? null
        : FirestoreInstance.instance.collection('users').doc(user.uid);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        return Scaffold(
          backgroundColor: _fondo,
          drawer: isDesktop
              ? null
              : Drawer(
                  width: 285,
                  child: SafeArea(child: _buildSidebar(user?.email ?? '')),
                ),
          appBar: isDesktop
              ? null
              : AppBar(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  title: const Text(
                    'CHAMPIONS RING',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Cerrar sesión',
                      onPressed: _cerrarSesion,
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
          body: SafeArea(
            top: isDesktop,
            child: Row(
              children: [
                if (isDesktop)
                  SizedBox(width: 265, child: _buildSidebar(user?.email ?? '')),
                Expanded(
                  child: userDocument == null
                      ? const Center(
                          child: Text('Inicia sesión para continuar.'),
                        )
                      : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: userDocument.snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Center(
                                child: Text(
                                  'No se pudo cargar la información.',
                                ),
                              );
                            }

                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final data = snapshot.data?.data() ?? {};

                            return _buildContent(
                              data: data,
                              email: user?.email ?? '',
                              isDesktop: isDesktop,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebar(String email) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 16, 24),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _rojo,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sports_mma,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'CHAMPIONS\nRING',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      height: 1.15,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
              children: [
                _buildSectionTitle('GENERAL'),
                _buildMenuItem(0),
                const SizedBox(height: 18),
                _buildSectionTitle('MI CUENTA'),
                _buildMenuItem(1),
                _buildMenuItem(2),
                const SizedBox(height: 18),
                _buildSectionTitle('COMPRAS'),
                _buildMenuItem(3),
                _buildMenuItem(4),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 19,
                  backgroundColor: Color(0xFFFFE8E9),
                  child: Icon(Icons.person_outline, color: _rojo),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mi cuenta',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: _gris),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar sesión',
                  onPressed: _cerrarSesion,
                  icon: const Icon(Icons.logout, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: _gris,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildMenuItem(int index) {
    final option = _options[index];
    final selected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        selected: selected,
        selectedTileColor: const Color(0xFFFFECEC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(option.icon, color: selected ? _rojo : _gris, size: 21),
        title: Text(
          option.title,
          style: TextStyle(
            color: selected ? _rojo : _texto,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        onTap: () {
          _seleccionarOpcion(index);

          if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildContent({
    required Map<String, dynamic> data,
    required String email,
    required bool isDesktop,
  }) {
    switch (_selectedIndex) {
      case 0:
        return _DashboardContent(
          data: data,
          email: email,
          isDesktop: isDesktop,
          onNavigate: _seleccionarOpcion,
        );

      case 1:
        return const ProfileScreen();

      case 2:
        return const DocumentsScreen();

      case 3:
        return const _SectionPlaceholder(
          title: 'Tienda y equipamiento',
          description:
              'Aquí podrás consultar los artículos disponibles del gimnasio.',
          icon: Icons.shopping_bag_outlined,
        );

      case 4:
        return const _SectionPlaceholder(
          title: 'Mis compras',
          description:
              'Aquí podrás consultar el estado y el historial de tus pedidos.',
          icon: Icons.receipt_long_outlined,
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _DashboardContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final String email;
  final bool isDesktop;
  final ValueChanged<int> onNavigate;

  const _DashboardContent({
    required this.data,
    required this.email,
    required this.isDesktop,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final name = [
      data['name']?.toString() ?? '',
      data['last_name']?.toString() ?? '',
    ].where((part) => part.isNotEmpty).join(' ');

    final photoUrl = data['photo_url']?.toString() ?? '';
    final registrationPayed = data['registration_payed'] == true;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32 : 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inicio',
                style: TextStyle(
                  fontSize: isDesktop ? 28 : 24,
                  fontWeight: FontWeight.w900,
                  color: _texto,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Bienvenido a tu espacio de Champion’s Ring.',
                style: TextStyle(color: _gris, fontSize: 14),
              ),
              const SizedBox(height: 26),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: isDesktop ? 34 : 28,
                      backgroundColor: const Color(0xFFFFE8E9),
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl.isEmpty
                          ? const Icon(Icons.person, color: _rojo, size: 32)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¡Hola, boxeador!',
                            style: TextStyle(color: _gris, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name.isEmpty ? 'Mi cuenta' : name,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(color: _gris, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: registrationPayed
                      ? const Color(0xFFF0FAF4)
                      : const Color(0xFFFFF4F4),
                  border: Border.all(
                    color: registrationPayed ? const Color(0xFFB8E6CA) : _rojo,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      registrationPayed
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      color: registrationPayed
                          ? const Color(0xFF20864B)
                          : _rojo,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            registrationPayed
                                ? 'Registro pagado'
                                : 'Registro pendiente de pago',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            registrationPayed
                                ? 'Tu registro aparece como pagado.'
                                : 'Consulta con recepción el estado de tu pago para confirmar tu acceso.',
                            style: const TextStyle(fontSize: 13, color: _gris),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Accesos rápidos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: isDesktop ? 3 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isDesktop ? 1.8 : 1.15,
                children: [
                  _QuickAction(
                    title: 'Mi perfil',
                    subtitle: 'Datos personales',
                    icon: Icons.person_outline,
                    onTap: () => onNavigate(1),
                  ),
                  _QuickAction(
                    title: 'Documentos',
                    subtitle: 'INE, CURP y más',
                    icon: Icons.folder_outlined,
                    onTap: () => onNavigate(2),
                  ),
                  _QuickAction(
                    title: 'Tienda',
                    subtitle: 'Ver equipamiento',
                    icon: Icons.shopping_bag_outlined,
                    onTap: () => onNavigate(3),
                  ),
                  _QuickAction(
                    title: 'Mis compras',
                    subtitle: 'Estado de pedidos',
                    icon: Icons.receipt_long_outlined,
                    onTap: () => onNavigate(4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8E8E8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _rojo, size: 25),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: _gris, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _SectionPlaceholder({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 38, color: _rojo),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _gris,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Este apartado se conectará con sus funciones en el siguiente paso.',
                  style: TextStyle(fontSize: 12, color: _gris),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuOption {
  final String title;
  final IconData icon;
  final String section;

  const _MenuOption({
    required this.title,
    required this.icon,
    required this.section,
  });
}
