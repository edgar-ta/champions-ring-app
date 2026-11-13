const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Ej. "25 de octubre de 2026, 18:30".
String formatearFecha(DateTime fecha) {
  final hora = fecha.hour.toString().padLeft(2, '0');
  final minuto = fecha.minute.toString().padLeft(2, '0');
  return '${fecha.day} de ${_meses[fecha.month - 1]} de ${fecha.year}, '
      '$hora:$minuto';
}

String duracionTexto(int dias) => switch (dias) {
  1 => '1 día',
  7 => '1 semana (7 días)',
  30 => '1 mes (30 días)',
  _ => '$dias días',
};

/// Frecuencia del cobro automático, ej. "cada semana".
String periodoTexto(int dias) => switch (dias) {
  7 => 'cada semana',
  _ => 'cada $dias días',
};

String tiempoRestante(Duration restante) {
  if (restante.inDays >= 1) {
    final dias = restante.inDays;
    return dias == 1 ? '1 día' : '$dias días';
  }
  if (restante.inHours >= 1) {
    final horas = restante.inHours;
    return horas == 1 ? '1 hora' : '$horas horas';
  }
  return 'Menos de 1 hora';
}
