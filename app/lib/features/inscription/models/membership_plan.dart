/// Opciones de plan que se muestran en el paso de selección.
class MembershipPlan {
  final int id; // 2 = semana, 3 = mes
  final String label;
  final String title;
  final String validity;
  final int price; // en MXN
  final List<String> benefits;

  const MembershipPlan({
    required this.id,
    required this.label,
    required this.title,
    required this.validity,
    required this.price,
    required this.benefits,
  });
}

const List<MembershipPlan> memberships = [
  MembershipPlan(
    id: 2,
    label: 'SEMANA',
    title: 'Acceso por 1 semana',
    validity: 'Válido por 7 días naturales',
    price: 180,
    benefits: [
      'Clases de boxeo ilimitadas',
      'Acceso completo a todas las áreas',
      'Asesoría básica de entrenamiento',
    ],
  ),
  MembershipPlan(
    id: 3,
    label: 'MES',
    title: 'Acceso por 1 mes',
    validity: 'Suscripción mensual recurrente',
    price: 600,
    benefits: [
      'Clases de boxeo y sparring ilimitadas',
      'Acceso preferente a eventos del club',
      '1 sesión de entrenamiento personalizado',
      'Casillero privado incluido',
    ],
  ),
];
