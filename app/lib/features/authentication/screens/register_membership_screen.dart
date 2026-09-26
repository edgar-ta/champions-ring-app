import 'package:flutter/material.dart';

import '../widgets/authentication_header.dart';
import '../widgets/register_progress.dart';

class RegisterMembershipScreen extends StatefulWidget {
  const RegisterMembershipScreen({super.key});

  @override
  State<RegisterMembershipScreen> createState() =>
      _RegisterMembershipScreenState();
}

class _RegisterMembershipScreenState extends State<RegisterMembershipScreen> {
  int _selectedMembership = 2;

  final List<MembershipOption> _memberships = [
    MembershipOption(
      tag: 'DÍA',
      title: 'Acceso por 1 día',
      subtitle: 'Válido por 24 horas',
      price: '\$150',
      benefits: [
        'Acceso completo al área de pesas',
        '1 clase grupal de boxeo a elegir',
        'Uso de regaderas y vestidores',
      ],
    ),
    MembershipOption(
      tag: 'SEMANA',
      title: 'Acceso por 1 semana',
      subtitle: 'Válido por 7 días naturales',
      price: '\$450',
      benefits: [
        'Clases de boxeo ilimitadas',
        'Acceso completo a todas las áreas',
        'Asesoría básica de entrenamiento',
      ],
    ),
    MembershipOption(
      tag: 'MES',
      title: 'Acceso por 1 mes',
      subtitle: 'Suscripción mensual recurrente',
      price: '\$1,200',
      benefits: [
        'Clases de boxeo y sparring ilimitadas',
        'Acceso preferente a eventos del club',
        '1 sesión de entrenamiento personalizado',
        'Casillero privado incluido',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthenticationHeader(
                showBackButton: true,
                onBackPressed: () {
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 28),

              const RegisterProgress(currentStep: 3, totalSteps: 4),

              const SizedBox(height: 30),

              const Text(
                'Elige tu membresía',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F1F1F),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Selecciona la opción de entrenamiento que mejor '
                'se adapte a tus metas en el ring.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF777777),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              ...List.generate(_memberships.length, (index) {
                final membership = _memberships[index];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == _memberships.length - 1 ? 0 : 16,
                  ),
                  child: _MembershipCard(
                    membership: membership,
                    selected: _selectedMembership == index,
                    onTap: () {
                      setState(() {
                        _selectedMembership = index;
                      });
                    },
                  ),
                );
              }),

              const SizedBox(height: 26),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3044),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'CONTINUAR',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 13,
                    ),
                    children: [
                      const TextSpan(text: '¿Ya tienes una cuenta? '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.popUntil(
                              context,
                              (route) => route.isFirst,
                            );
                          },
                          child: const Text(
                            'Inicia sesión',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class MembershipOption {
  const MembershipOption({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.benefits,
  });

  final String tag;
  final String title;
  final String subtitle;
  final String price;
  final List<String> benefits;
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({
    required this.membership,
    required this.selected,
    required this.onTap,
  });

  final MembershipOption membership;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF3044);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF5F5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? primaryColor : const Color(0xFFE2E2E2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? primaryColor : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    membership.tag,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : const Color(0xFF777777),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 23,
                  height: 23,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? primaryColor : const Color(0xFFC9C9C9),
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: const BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 7),

            Text(
              membership.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF222222),
              ),
            ),

            const SizedBox(height: 4),

            Text(
              membership.subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF777777)),
            ),

            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  membership.price,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(width: 5),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'MXN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF777777),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            const Divider(color: Color(0xFFE2E2E2), height: 1),

            const SizedBox(height: 12),

            ...membership.benefits.map((benefit) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 17,
                      color: selected ? primaryColor : const Color(0xFF7A828C),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF444444),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
