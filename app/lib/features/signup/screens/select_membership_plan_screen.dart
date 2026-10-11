import 'package:flutter/material.dart';

import '../models/membership_plan.dart';
import '../widgets/registro_pagina.dart';
import '../widgets/tarjeta_membresia.dart';
import 'visualize_waiver_screen.dart';

/// Paso 3: elegir la membresía.
class SelectMembershipPlanScreen extends StatefulWidget {
  const SelectMembershipPlanScreen({super.key});

  @override
  State<SelectMembershipPlanScreen> createState() =>
      _SelectMembershipPlanScreenState();
}

class _SelectMembershipPlanScreenState
    extends State<SelectMembershipPlanScreen> {
  // La membresía mensual viene seleccionada por defecto, como en el diseño.
  int _selectedPlan = 3;

  void _moveToNextRegistrationStep() {
    final elegida = memberships.firstWhere((m) => m.id == _selectedPlan);
    debugPrint('Membresía elegida: ${elegida.title} (\$${elegida.price} MXN)');
    // TODO: guardar la membresía elegida en Firestore.
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const VisualizeWaiverScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return RegistroPagina(
      paso: 3,
      nombrePaso: 'Membresía',
      siguiente: 'Responsiva',
      titulo: 'Elige tu membresía',
      subtitulo: 'Selecciona la opción de entrenamiento que mejor se adapte a tus metas en el ring.',
      child: Column(
        children: [
          for (final m in memberships) ...[
            TarjetaMembresia(
              membresia: m,
              seleccionada: m.id == _selectedPlan,
              onTap: () => setState(() => _selectedPlan = m.id),
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 10),
          BotonRojo(texto: 'CONTINUAR', onPressed: _moveToNextRegistrationStep),
        ],
      ),
    );
  }
}
