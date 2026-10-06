import 'package:flutter/material.dart';

import '../models/membresia.dart';
import '../widgets/registro_pagina.dart';
import '../widgets/tarjeta_membresia.dart';
import 'carta_responsiva_screen.dart';

/// Paso 3: elegir la membresía.
class MembresiaScreen extends StatefulWidget {
  const MembresiaScreen({super.key});

  @override
  State<MembresiaScreen> createState() => _MembresiaScreenState();
}

class _MembresiaScreenState extends State<MembresiaScreen> {
  // La membresía mensual viene seleccionada por defecto, como en el diseño.
  int _seleccionada = 3;

  void _continuar() {
    final elegida = membresias.firstWhere((m) => m.id == _seleccionada);
    debugPrint('Membresía elegida: ${elegida.titulo} (\$${elegida.precio} MXN)');
    // TODO: guardar la membresía elegida en Firestore.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CartaResponsivaScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RegistroPagina(
      paso: 3,
      nombrePaso: 'Membresía',
      siguiente: 'Responsiva',
      titulo: 'Elige tu membresía',
      subtitulo:
          'Selecciona la opción de entrenamiento que mejor se adapte a tus metas en el ring.',
      child: Column(
        children: [
          for (final m in membresias) ...[
            TarjetaMembresia(
              membresia: m,
              seleccionada: m.id == _seleccionada,
              onTap: () => setState(() => _seleccionada = m.id),
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 10),
          BotonRojo(texto: 'CONTINUAR', onPressed: _continuar),
        ],
      ),
    );
  }
}