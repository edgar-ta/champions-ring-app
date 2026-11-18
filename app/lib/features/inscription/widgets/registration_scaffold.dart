import 'package:flutter/material.dart';

import '../../../shared/ui/colors.dart';
import '../../../shared/ui/text_styles.dart';

const Color _gris = Color(0xFF6B6B6B);

/// Estructura común de todos los pasos: cabecera con progreso, título,
/// contenido y pie.
class RegistrationScaffold extends StatelessWidget {
  final int stepIndex; // 1..totalSteps
  final int totalSteps;
  final String stepName;
  final String? nextStepName;
  final String? title;
  final String? subtitle;
  final String headerTitle; // texto junto al logo
  final bool isLoading;
  final bool showFooter; // oculta el pie
  final bool blockScrolling;
  final Widget? footer; // si es null se usa "¿Ya tienes una cuenta?"
  final Widget child;
  final Widget? bottomActions;
  final VoidCallback? onBack;

  const RegistrationScaffold({
    super.key,
    required this.stepIndex,
    required this.stepName,
    required this.child,
    this.totalSteps = 4,
    this.onBack,
    this.nextStepName,
    this.title,
    this.subtitle,
    this.headerTitle = 'CHAMPIONS RING',
    this.isLoading = false,
    this.showFooter = false,
    this.blockScrolling = false,
    this.footer,
    this.bottomActions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        stepIndex: stepIndex,
                        totalSteps: totalSteps,
                        stepName: stepName,
                        nextStepName: nextStepName,
                        headerTitle: headerTitle,
                        onBack: onBack,
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
                        Text(subtitle!, style: SharedTextStyles.formSupporting),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) => Center(
                        child: SizedBox(
                          width: constraints.maxWidth < 480
                              ? constraints.maxWidth
                              : 480,
                          height: constraints.maxHeight,
                          child: AbsorbPointer(
                            absorbing: isLoading,
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isLoading)
                    const ColoredBox(
                      color: Colors.black26,
                      child: Center(
                        child: CircularProgressIndicator(color: kRojo),
                      ),
                    ),
                ],
              ),
            ),
            if (showFooter)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child:
                    footer ??
                    RegistrationFooter(
                      text: '¿Ya tienes una cuenta? ',
                      action: 'Inicia sesión',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: bottomActions == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE8E8E8))),
                ),
                child: Align(
                  alignment: Alignment.center,
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: AbsorbPointer(
                      absorbing: isLoading,
                      child: bottomActions,
                    ),
                  ),
                ),
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
  final int totalSteps;
  final String stepName;
  final String? nextStepName;
  final String headerTitle;
  final VoidCallback? onBack;

  const _Header({
    required this.stepIndex,
    required this.totalSteps,
    required this.stepName,
    required this.headerTitle,
    this.onBack,
    this.nextStepName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            InkWell(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
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
          children: List.generate(totalSteps, (i) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
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
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Paso $stepIndex de $totalSteps: ',
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
            ),
            if (nextStepName != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Siguiente: $nextStepName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 11, color: _gris),
                ),
              ),
            ],
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
