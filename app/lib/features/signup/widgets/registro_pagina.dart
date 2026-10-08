import 'package:flutter/material.dart';

import 'registro_form.dart' show kRojo;

const Color _gris = Color(0xFF6B6B6B);

/// Estructura común de todos los pasos: cabecera con progreso, título,
/// contenido y pie.
class RegistroPagina extends StatelessWidget {
  final int paso; // 1..4
  final String nombrePaso;
  final String? siguiente;
  final String? titulo;
  final String? subtitulo;
  final String tituloCabecera; // texto junto al logo
  final bool cargando;
  final bool sinPie; // oculta el pie
  final bool bloquearScroll; // útil mientras se dibuja la firma
  final Widget? pie; // si es null se usa "¿Ya tienes una cuenta?"
  final Widget child;

  const RegistroPagina({
    super.key,
    required this.paso,
    required this.nombrePaso,
    required this.child,
    this.siguiente,
    this.titulo,
    this.subtitulo,
    this.tituloCabecera = 'CHAMPIONS RING',
    this.cargando = false,
    this.sinPie = false,
    this.bloquearScroll = false,
    this.pie,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: bloquearScroll ? const NeverScrollableScrollPhysics() : null,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: AbsorbPointer(
                    absorbing: cargando,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Cabecera(
                          paso: paso,
                          nombrePaso: nombrePaso,
                          siguiente: siguiente,
                          tituloCabecera: tituloCabecera,
                        ),
                        const SizedBox(height: 24),
                        if (titulo != null)
                          Text(titulo!,
                              style: const TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w800)),
                        if (subtitulo != null) ...[
                          const SizedBox(height: 6),
                          Text(subtitulo!,
                              style: const TextStyle(
                                  fontSize: 13, color: _gris, height: 1.3)),
                        ],
                        if (titulo != null || subtitulo != null)
                          const SizedBox(height: 20),
                        child,
                        if (!sinPie) ...[
                          const SizedBox(height: 12),
                          pie ??
                              PiePagina(
                                texto: '¿Ya tienes una cuenta? ',
                                accion: 'Inicia sesión',
                                // TODO: navegar a la pantalla de inicio de sesión
                                onTap: () => Navigator.of(context).maybePop(),
                              ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (cargando)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: Center(child: CircularProgressIndicator(color: kRojo)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pie de página: texto gris + acción en negritas.
class PiePagina extends StatelessWidget {
  final String texto;
  final String accion;
  final VoidCallback? onTap;
  final bool subrayar;

  const PiePagina({
    super.key,
    required this.texto,
    required this.accion,
    this.onTap,
    this.subrayar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(texto, style: const TextStyle(fontSize: 12, color: _gris)),
            Text(
              accion,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                decoration: subrayar ? TextDecoration.underline : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón rojo grande con resplandor. Con onPressed null se ve deshabilitado (gris).
class BotonRojo extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;

  const BotonRojo({
    super.key,
    required this.texto,
    required this.onPressed,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    final activo = onPressed != null;
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: activo
            ? [
                BoxShadow(
                  color: kRojo.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kRojo,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFF1F1F1),
          disabledForegroundColor: const Color(0xFFB5B5B5),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icono != null) ...[
              Icon(icono, size: 18),
              const SizedBox(width: 8),
            ],
            Text(texto,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }
}

/// Botón blanco con borde (acciones secundarias como CANCELAR).
class BotonBlanco extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;

  const BotonBlanco({super.key, required this.texto, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A1A1A),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE3E3E3)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(texto,
            style: const TextStyle(
                fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  final int paso;
  final String nombrePaso;
  final String? siguiente;
  final String tituloCabecera;

  const _Cabecera({
    required this.paso,
    required this.nombrePaso,
    required this.tituloCabecera,
    this.siguiente,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              customBorder: const CircleBorder(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE3E3E3)),
                ),
                child: const Icon(Icons.chevron_left, size: 22),
              ),
            ),
            Expanded(child: Center(child: _Logo(texto: tituloCabecera))),
            const SizedBox(width: 36),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                decoration: BoxDecoration(
                  color: i < paso ? kRojo : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Paso $paso de 4: ',
                    style: const TextStyle(
                        color: kRojo, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: nombrePaso,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 11),
            ),
            if (siguiente != null)
              Text('Siguiente: $siguiente',
                  style: const TextStyle(fontSize: 11, color: _gris)),
          ],
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  final String texto;

  const _Logo({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: kRojo,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.sports_mma,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }
}