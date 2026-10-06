import 'package:flutter/material.dart';

import '../widgets/lienzo_firma.dart';
import '../widgets/registro_form.dart' show kRojo;
import '../widgets/registro_pagina.dart';

/// Pantalla "Firma digital". Al confirmar devuelve la firma como PNG
/// (Uint8List) con Navigator.pop; al cancelar devuelve null.
class FirmaScreen extends StatefulWidget {
  const FirmaScreen({super.key});

  @override
  State<FirmaScreen> createState() => _FirmaScreenState();
}

class _FirmaScreenState extends State<FirmaScreen> {
  final _controlador = ControladorFirma();
  bool _dibujando = false;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_controlador.vacio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dibuja tu firma para continuar')),
      );
      return;
    }
    final bytes = await _controlador.exportarPng();
    if (!mounted) return;
    Navigator.of(context).pop(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return RegistroPagina(
      paso: 4,
      nombrePaso: 'Responsiva',
      siguiente: 'Finalizar',
      tituloCabecera: 'FIRMA DIGITAL',
      titulo: 'Firma digital',
      subtitulo:
          'Por favor dibuja tu firma con el dedo en el espacio indicado para autorizar legalmente tu responsiva escolar.',
      sinPie: true,
      bloquearScroll: _dibujando,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Lienzo de firma',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B6B6B),
                      fontWeight: FontWeight.w500)),
              TextButton.icon(
                onPressed: _controlador.limpiar,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.refresh, size: 16, color: kRojo),
                label: const Text('LIMPIAR',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kRojo)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LienzoFirma(
            controlador: _controlador,
            onDibujando: (v) => setState(() => _dibujando = v),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBD4FA)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF2B6CD4), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'La firma se estampará automáticamente en el documento en formato PDF para el archivo escolar definitivo.',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF2B5FB8), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          BotonRojo(texto: 'CONFIRMAR FIRMA', onPressed: _confirmar),
          const SizedBox(height: 12),
          BotonBlanco(
            texto: 'CANCELAR',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}