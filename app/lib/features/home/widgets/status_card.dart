import 'package:flutter/material.dart';

export '../../inscription/widgets/personal_data_form.dart' show kRojo;

const kGris = Color(0xFF6B6B6B);
const kVerde = Color(0xFF2E9E5B);
const kAmbar = Color(0xFFE09B1A);

/// Tarjeta de estado: título con ícono, descripción, filas
/// etiqueta/valor y un botón opcional.
class StatusCard extends StatelessWidget {
  final Color color;
  final IconData icono;
  final String titulo;
  final String descripcion;
  final List<(String, String)> filas;
  final Widget? accion;

  const StatusCard({
    super.key,
    required this.color,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    this.filas = const [],
    this.accion,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(descripcion, style: const TextStyle(height: 1.4)),
        if (filas.isNotEmpty) ...[
          const Divider(height: 28),
          for (final (etiqueta, valor) in filas)
            _Fila(etiqueta: etiqueta, valor: valor),
        ],
        if (accion != null) ...[const SizedBox(height: 12), accion!],
      ],
    ),
  );
}

class _Fila extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Fila({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            etiqueta,
            style: const TextStyle(color: kGris, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            valor,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
