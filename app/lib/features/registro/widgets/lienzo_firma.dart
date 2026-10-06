import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Guarda los trazos de la firma y la exporta como PNG (fondo transparente).
class ControladorFirma extends ChangeNotifier {
  final List<List<Offset>> _trazos = [];
  Size tamano = Size.zero;

  List<List<Offset>> get trazos => _trazos;
  bool get vacio => _trazos.isEmpty;

  void iniciarTrazo(Offset p) {
    _trazos.add([p]);
    notifyListeners();
  }

  void agregarPunto(Offset p) {
    if (_trazos.isEmpty) return;
    _trazos.last.add(p);
    notifyListeners();
  }

  void limpiar() {
    _trazos.clear();
    notifyListeners();
  }

  static void pintar(Canvas canvas, List<List<Offset>> trazos) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final t in trazos) {
      if (t.length == 1) {
        canvas.drawCircle(t.first, 1.4, Paint()..color = paint.color);
        continue;
      }
      final path = Path()..moveTo(t.first.dx, t.first.dy);
      for (var i = 1; i < t.length; i++) {
        path.lineTo(t[i].dx, t[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  Future<Uint8List?> exportarPng() async {
    if (vacio || tamano.isEmpty) return null;
    const escala = 2.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(escala);
    pintar(canvas, _trazos);
    final imagen = await recorder.endRecording().toImage(
          (tamano.width * escala).ceil(),
          (tamano.height * escala).ceil(),
        );
    final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
    return datos?.buffer.asUint8List();
  }
}

/// Lienzo para dibujar la firma con el dedo.
class LienzoFirma extends StatelessWidget {
  final ControladorFirma controlador;

  /// Avisa cuando el dedo está dibujando (para bloquear el scroll de la página).
  final ValueChanged<bool>? onDibujando;

  const LienzoFirma({super.key, required this.controlador, this.onDibujando});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E3E3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: LayoutBuilder(
          builder: (context, c) {
            controlador.tamano = c.biggest;
            return Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                onDibujando?.call(true);
                controlador.iniciarTrazo(e.localPosition);
              },
              onPointerMove: (e) => controlador.agregarPunto(e.localPosition),
              onPointerUp: (_) => onDibujando?.call(false),
              onPointerCancel: (_) => onDibujando?.call(false),
              child: Stack(
                children: [
                  // Ícono de ayuda mientras no hay firma
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ListenableBuilder(
                        listenable: controlador,
                        builder: (_, __) => controlador.vacio
                            ? const Center(
                                child: Icon(Icons.draw_outlined,
                                    size: 72, color: Color(0xFFD0D0D0)),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  // Línea punteada + "Firma aquí" / "X"
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 12,
                    child: IgnorePointer(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox(
                            height: 1,
                            width: double.infinity,
                            child: CustomPaint(painter: _LineaPunteada()),
                          ),
                          SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Firma aquí',
                                  style: TextStyle(
                                      fontSize: 10, color: Color(0xFF8A8A8A))),
                              Text('X',
                                  style: TextStyle(
                                      fontSize: 10, color: Color(0xFF8A8A8A))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Trazos de la firma
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _PintorFirma(controlador)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PintorFirma extends CustomPainter {
  final ControladorFirma controlador;

  _PintorFirma(this.controlador) : super(repaint: controlador);

  @override
  void paint(Canvas canvas, Size size) =>
      ControladorFirma.pintar(canvas, controlador.trazos);

  @override
  bool shouldRepaint(covariant _PintorFirma oldDelegate) =>
      oldDelegate.controlador != controlador;
}

class _LineaPunteada extends CustomPainter {
  const _LineaPunteada();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 3, 0), paint);
      x += 6;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}