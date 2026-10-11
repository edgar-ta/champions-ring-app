import 'package:flutter/material.dart';

import 'personal_data_form.dart' show kRojo;

const Color _gris = Color(0xFF6B6B6B);

/// Estructura común de todos los pasos: cabecera con progreso, título,
/// contenido y pie.
class RegistrationScaffold extends StatelessWidget {
  final int stepIndex; // 1..4
  final String stepName;
  final String? nextStepName;
  final String? title;
  final String? subtitle;
  final String headerTitle; // texto junto al logo
  final bool isLoading;
  final bool showFooter; // oculta el pie
  final bool blockScrolling; // útil mientras se dibuja la firma
  final Widget? footer; // si es null se usa "¿Ya tienes una cuenta?"
  final Widget child;

  const RegistrationScaffold({
    super.key,
    required this.stepIndex,
    required this.stepName,
    required this.child,
    this.nextStepName,
    this.title,
    this.subtitle,
    this.headerTitle = 'CHAMPIONS RING',
    this.isLoading = false,
    this.showFooter = false,
    this.blockScrolling = false,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: blockScrolling
                  ? const NeverScrollableScrollPhysics()
                  : null,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: AbsorbPointer(
                    absorbing: isLoading,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          stepIndex: stepIndex,
                          stepName: stepName,
                          nextStepName: nextStepName,
                          headerTitle: headerTitle,
                        ),
                        const SizedBox(height: 24),
                        if (title != null)
                          Text(
                            title!,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _gris,
                              height: 1.3,
                            ),
                          ),
                        ],
                        if (title != null || subtitle != null)
                          const SizedBox(height: 20),
                        child,
                        if (showFooter) ...[
                          const SizedBox(height: 12),
                          footer ??
                              RegistrationFooter(
                                text: '¿Ya tienes una cuenta? ',
                                action: 'Inicia sesión',
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
            if (isLoading)
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
class RegistrationFooter extends StatelessWidget {
  final String text;
  final String action;
  final VoidCallback? onTap;
  final bool underlineAction;

  const RegistrationFooter({
    super.key,
    required this.text,
    required this.action,
    this.onTap,
    this.underlineAction = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: const TextStyle(fontSize: 12, color: _gris)),
            Text(
              action,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                decoration: underlineAction ? TextDecoration.underline : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón rojo grande con resplandor. Con onPressed null se ve deshabilitado (gris).
class RedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const RedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón blanco con borde (acciones secundarias como CANCELAR).
class WhiteButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const WhiteButton({super.key, required this.text, required this.onPressed});

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int stepIndex;
  final String stepName;
  final String? nextStepName;
  final String headerTitle;

  const _Header({
    required this.stepIndex,
    required this.stepName,
    required this.headerTitle,
    this.nextStepName,
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
            Expanded(
              child: Center(child: _Logo(text: headerTitle)),
            ),
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
                  color: i < stepIndex ? kRojo : const Color(0xFFE0E0E0),
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
                    text: 'Paso $stepIndex de 4: ',
                    style: const TextStyle(
                      color: kRojo,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: stepName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 11),
            ),
            if (nextStepName != null)
              Text(
                'Siguiente: $nextStepName',
                style: const TextStyle(fontSize: 11, color: _gris),
              ),
          ],
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  final String text;

  const _Logo({required this.text});

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
          child: const Icon(Icons.sports_mma, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
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
