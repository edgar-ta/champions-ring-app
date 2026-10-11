import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Guarda los trazos de la firma y la exporta como PNG (fondo transparente).
class SignatureController extends ChangeNotifier {
  final List<List<Offset>> _strokes = [];
  Size size = Size.zero;

  List<List<Offset>> get strokes => _strokes;
  bool get isEmpty => _strokes.isEmpty;

  void beginStroke(Offset p) {
    _strokes.add([p]);
    notifyListeners();
  }

  void addPoint(Offset p) {
    if (_strokes.isEmpty) return;
    _strokes.last.add(p);
    notifyListeners();
  }

  void clear() {
    _strokes.clear();
    notifyListeners();
  }

  static void paint(Canvas canvas, List<List<Offset>> trazos) {
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

  Future<Uint8List?> exportPng() async {
    if (isEmpty || size.isEmpty) return null;
    const escala = 2.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(escala);
    paint(canvas, _strokes);
    final imagen = await recorder.endRecording().toImage(
      (size.width * escala).ceil(),
      (size.height * escala).ceil(),
    );
    final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
    return datos?.buffer.asUint8List();
  }
}

/// Lienzo para dibujar la firma con el dedo.
class SignatureCanvas extends StatelessWidget {
  final SignatureController ctrl;

  /// Avisa cuando el dedo está dibujando (para bloquear el scroll de la página).
  final ValueChanged<bool>? onDrawing;

  const SignatureCanvas({super.key, required this.ctrl, this.onDrawing});

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
            ctrl.size = c.biggest;
            return Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                onDrawing?.call(true);
                ctrl.beginStroke(e.localPosition);
              },
              onPointerMove: (e) => ctrl.addPoint(e.localPosition),
              onPointerUp: (_) => onDrawing?.call(false),
              onPointerCancel: (_) => onDrawing?.call(false),
              child: Stack(
                children: [
                  // Ícono de ayuda mientras no hay firma
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ListenableBuilder(
                        listenable: ctrl,
                        builder: (_, __) => ctrl.isEmpty
                            ? const Center(
                                child: Icon(
                                  Icons.draw_outlined,
                                  size: 72,
                                  color: Color(0xFFD0D0D0),
                                ),
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
                            child: CustomPaint(painter: _DottedLinePainter()),
                          ),
                          SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Firma aquí',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF8A8A8A),
                                ),
                              ),
                              Text(
                                'X',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF8A8A8A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Trazos de la firma
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _SignaturePainter(ctrl)),
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

class _SignaturePainter extends CustomPainter {
  final SignatureController ctrl;

  _SignaturePainter(this.ctrl) : super(repaint: ctrl);

  @override
  void paint(Canvas canvas, Size size) =>
      SignatureController.paint(canvas, ctrl.strokes);

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) =>
      oldDelegate.ctrl != ctrl;
}

class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter();

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
