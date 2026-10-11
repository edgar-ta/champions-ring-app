/// Opciones de membresía que se muestran en el paso 3.
class MembershipPlan {
  final int id; // 1 = día, 2 = semana, 3 = mes
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
    id: 1,
    label: 'DÍA',
    title: 'Acceso por 1 día',
    validity: 'Válido por 24 horas',
    price: 69,
    benefits: [
      'Acceso completo al área de pesas',
      '1 clase grupal de boxeo a elegir',
      'Uso de regaderas y vestidores',
    ],
  ),
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
