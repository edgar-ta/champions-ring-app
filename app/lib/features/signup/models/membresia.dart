/// Opciones de membresía que se muestran en el paso 3.
class Membresia {
  final int id; // 1 = día, 2 = semana, 3 = mes
  final String etiqueta;
  final String titulo;
  final String vigencia;
  final int precio; // en MXN
  final List<String> beneficios;

  const Membresia({
    required this.id,
    required this.etiqueta,
    required this.titulo,
    required this.vigencia,
    required this.precio,
    required this.beneficios,
  });
}

const List<Membresia> membresias = [
  Membresia(
    id: 1,
    etiqueta: 'DÍA',
    titulo: 'Acceso por 1 día',
    vigencia: 'Válido por 24 horas',
    precio: 69,
    beneficios: [
      'Acceso completo al área de pesas',
      '1 clase grupal de boxeo a elegir',
      'Uso de regaderas y vestidores',
    ],
  ),
  Membresia(
    id: 2,
    etiqueta: 'SEMANA',
    titulo: 'Acceso por 1 semana',
    vigencia: 'Válido por 7 días naturales',
    precio: 180,
    beneficios: [
      'Clases de boxeo ilimitadas',
      'Acceso completo a todas las áreas',
      'Asesoría básica de entrenamiento',
    ],
  ),
  Membresia(
    id: 3,
    etiqueta: 'MES',
    titulo: 'Acceso por 1 mes',
    vigencia: 'Suscripción mensual recurrente',
    precio: 600,
    beneficios: [
      'Clases de boxeo y sparring ilimitadas',
      'Acceso preferente a eventos del club',
      '1 sesión de entrenamiento personalizado',
      'Casillero privado incluido',
    ],
  ),
];