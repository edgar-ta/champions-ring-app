import 'package:flutter/material.dart';

import '../models/membresia.dart';
import 'registro_form.dart' show kRojo;

/// Tarjeta seleccionable de una membresía (con radio, precio y beneficios).
class TarjetaMembresia extends StatelessWidget {
  final Membresia membresia;
  final bool seleccionada;
  final VoidCallback onTap;

  const TarjetaMembresia({
    super.key,
    required this.membresia,
    required this.seleccionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final acento = seleccionada ? kRojo : const Color(0xFF7A7A7A);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: seleccionada ? const Color(0xFFFFF1F1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionada ? kRojo : const Color(0xFFE3E3E3),
            width: seleccionada ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: seleccionada ? kRojo : const Color(0xFFECECEC),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    membresia.etiqueta,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: seleccionada
                          ? Colors.white
                          : const Color(0xFF555555),
                    ),
                  ),
                ),
                _Radio(seleccionado: seleccionada),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              membresia.titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              membresia.vigencia,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B)),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\$${membresia.precio}',
                  style:
                      const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 4),
                const Text(
                  'MXN',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B6B6B),
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: seleccionada
                  ? const Color(0xFFF2C4C7)
                  : const Color(0xFFE3E3E3),
            ),
            const SizedBox(height: 12),
            ...membresia.beneficios.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: acento),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(b,
                          style: const TextStyle(fontSize: 12.5, height: 1.2)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool seleccionado;

  const _Radio({required this.seleccionado});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: seleccionado ? kRojo : const Color(0xFFBDBDBD),
          width: 2,
        ),
      ),
      child: seleccionado
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration:
                    const BoxDecoration(color: kRojo, shape: BoxShape.circle),
              ),
            )
          : null,
    );
  }
}