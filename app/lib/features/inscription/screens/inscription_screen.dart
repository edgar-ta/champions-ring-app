import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/core_payment.dart' show CorePaymentType;
import '../../../core/models/core_membership_plan.dart';
import '../../../core/repositories/core_membership_plan_repository.dart';
import '../../../core/utils/result.dart';
import '../models/member_inscription_data.dart';
import '../services/inscription_service.dart';
import '../widgets/personal_data_form.dart' show PersonalDataFormState;
import '../widgets/registration_scaffold.dart';
import 'register_account_validation_notice_screen.dart';
import 'register_id_screen.dart';
import 'register_payment_selection_screen.dart';
import 'register_payment_summary_screen.dart';
import 'register_personal_data_screen.dart';
import 'register_plan_selection_screen.dart';
import 'register_previous_inscription_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../login/screens/login_screen.dart';

/// Contenedor del wizard: mantiene los datos de cada paso en UserFormData.
class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  static const _maxDocumentBytes = 20 * 1024 * 1024;
  final _pages = PageController();
  final _personalDataFormKey = GlobalKey<PersonalDataFormState>();
  late MemberInscriptionData _formData;
  int _step = 0;
  bool _loading = false;
  bool _hasEditedPersonalData = false;
  List<CoreMembershipPlan>? _membershipPlans;
  bool _isLoadingMembershipPlans = false;
  Object? _membershipPlanLoadError;

  bool get _isReturningMember =>
      _formData.previousInscriptionData?.previouslySignedIn == true;

  int get _totalSteps => _isReturningMember ? 5 : 6;

  bool get _hasEnteredData =>
      _hasEditedPersonalData ||
      _formData.previousInscriptionData != null ||
      _formData.personalData != null ||
      _formData.idData != null ||
      _formData.planSelectionData != null ||
      _formData.paymentSelectionData != null;

  bool get _hasSelectedAvailablePlan {
    final selectedPlanUid = _formData.planSelectionData?.membershipPlanUid;
    return !_isLoadingMembershipPlans &&
        _membershipPlanLoadError == null &&
        (_membershipPlans ?? const <CoreMembershipPlan>[]).any(
          (plan) => plan.uid == selectedPlanUid,
        );
  }

  bool get _hasCompleteIdentification {
    final personal = _formData.personalData;
    final id = _formData.idData;
    if (personal == null ||
        id?.ineFrontBytes == null ||
        id?.ineBackBytes == null) {
      return false;
    }
    return personal.isOfLegalAge ||
        (id?.curpBytes != null &&
            id?.curpFormat != null &&
            (personal.guardianName?.trim().isNotEmpty ?? false) &&
            RegExp(r'^\+(52|1)\d{10}$')
                .hasMatch(personal.guardianPhone ?? '') &&
            (personal.guardianRelationship?.trim().isNotEmpty ?? false));
  }

  bool get _canContinue {
    if (_loading) return false;
    if (_step == 0) return _formData.previousInscriptionData != null;
    if (_isReturningMember) {
      return switch (_step) {
        1 || 2 => true,
        3 => _hasCompleteIdentification,
        4 => _hasSelectedAvailablePlan,
        _ => false,
      };
    }
    return switch (_step) {
      1 => true,
      2 => _hasCompleteIdentification,
      3 || 4 => _hasSelectedAvailablePlan,
      5 =>
        _formData.paymentSelectionData != null &&
            (_formData.paymentSelectionData?.paymentMethod !=
                    CorePaymentType.directTransfer ||
                (_formData.paymentSelectionData?.referenceId
                        ?.trim()
                        .isNotEmpty ??
                    false)),
      _ => false,
    };
  }

  String get _continueLabel =>
      _step == _totalSteps - 1 ? 'FINALIZAR' : 'CONTINUAR';

  @override
  void initState() {
    super.initState();
    _formData = MemberInscriptionData();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    setState(() => _step = step);
    if (_isMembershipPlanStep(step) &&
        _membershipPlans == null &&
        !_isLoadingMembershipPlans) {
      _loadActiveMembershipPlans();
    }
    _pages.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  bool _isMembershipPlanStep(int step) => step == (_isReturningMember ? 4 : 3);

  Future<void> _loadActiveMembershipPlans() async {
    setState(() {
      _isLoadingMembershipPlans = true;
      _membershipPlanLoadError = null;
    });

    try {
      final plans = await CoreMembershipPlanRepository()
          .getActiveMembershipPlans();
      if (!mounted) return;
      setState(() {
        _membershipPlans = plans;
        _isLoadingMembershipPlans = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _membershipPlanLoadError = error;
        _isLoadingMembershipPlans = false;
      });
    }
  }

  void _backStep() => _goToStep(_step - 1);

  Future<void> _requestExit() async {
    if (_hasEnteredData) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Salir del registro?'),
          content: const Text(
            'Si sales ahora, perderás los datos que ingresaste. '
            '¿Quieres salir de todos modos?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Continuar registrándome'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Salir'),
            ),
          ],
        ),
      );
      if (shouldExit != true || !mounted) return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _continueFromCurrentStep() async {
    if (_step == 0) {
      _goToStep(1);
    } else if (_isReturningMember) {
      switch (_step) {
        case 1:
          _goToStep(2);
          break;
        case 2:
          await _personalDataFormKey.currentState?.submit();
          break;
        case 3:
          _goToStep(4);
          break;
        case 4:
          await _complete();
          break;
      }
    } else {
      switch (_step) {
        case 1:
          await _personalDataFormKey.currentState?.submit();
          break;
        case 2:
          _goToStep(3);
          break;
        case 3:
          _goToStep(4);
          break;
        case 4:
          _goToStep(5);
          break;
        case 5:
          await _complete();
          break;
      }
    }
  }

  Widget _buildBottomActions() {
    return Row(
      children: [
        if (_step > 0) ...[
          Expanded(
            child: WhiteButton(text: 'REGRESAR', onPressed: _backStep),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: RedButton(
            text: _continueLabel,
            onPressed: _canContinue ? _continueFromCurrentStep : null,
          ),
        ),
      ],
    );
  }

  void _markPersonalDataChanged() {
    if (_hasEditedPersonalData) return;
    setState(() => _hasEditedPersonalData = true);
  }

  void _updatePersonalData(MemberInscription_PersonalData data) => setState(() {
    final previousPersonalData = _formData.personalData;
    final legalAgeStatusChanged =
        previousPersonalData != null &&
        previousPersonalData.isOfLegalAge != data.isOfLegalAge;

    _formData = _formData.copyWith(
      personalData: data,
      clearIdData: legalAgeStatusChanged,
    );
  });

  void _updatePreviousInscriptionData(
    MemberInscription_PreviousInscriptionData data,
  ) => setState(
    () => _formData = _formData.copyWith(previousInscriptionData: data),
  );

  void _updateIdData(MemberInscription_IdData data) =>
      setState(() => _formData = _formData.copyWith(idData: data));

  void _updatePlanData(MemberInscription_PlanSelectionData data) => setState(
    () => _formData = _formData.copyWith(
      planSelectionData: data,
      clearPaymentSelectionData: true,
    ),
  );

  void _updatePaymentData(MemberInscription_PaymentSelectionData data) =>
      setState(
        () => _formData = _formData.copyWith(paymentSelectionData: data),
      );

  Future<void> _complete() async {
    final previousInscription = _formData.previousInscriptionData;
    final personal = _formData.personalData;
    final id = _formData.idData;
    final plan = _formData.planSelectionData;
    final payment = _formData.paymentSelectionData;
    if (previousInscription == null ||
        personal == null ||
        id == null ||
        id.ineFrontBytes == null ||
        id.ineFrontFormat == null ||
        id.ineBackBytes == null ||
        id.ineBackFormat == null ||
        (!personal.isOfLegalAge &&
            (id.curpBytes == null || id.curpFormat == null)) ||
        plan == null ||
        (!_isReturningMember && payment == null)) {
      _showError('Completa todos los pasos del registro.');
      return;
    }
    if (!_isReturningMember &&
        payment?.paymentMethod == CorePaymentType.directTransfer &&
        (payment?.referenceId?.trim().isNotEmpty ?? false) == false) {
      _showError('Captura la referencia bancaria de la transferencia.');
      return;
    }
    if (personal.photoBytes.length > 5 * 1024 * 1024) {
      _showError('La foto de perfil no debe superar 5 MB.');
      return;
    }
    final documentSizes = [if (!personal.isOfLegalAge) id.curpBytes!.length];
    if (documentSizes.any((size) => size > _maxDocumentBytes)) {
      _showError('El CURP no debe pesar más de 20 MB.');
      return;
    }
    if (id.ineFrontBytes!.length > 5 * 1024 * 1024 ||
        id.ineBackBytes!.length > 5 * 1024 * 1024) {
      _showError('Cada lado de la INE debe pesar como máximo 5 MB.');
      return;
    }
    if (!personal.isOfLegalAge &&
        ((personal.guardianName?.trim().isNotEmpty ?? false) == false ||
            !RegExp(r'^\+(52|1)\d{10}$')
                .hasMatch(personal.guardianPhone ?? '') ||
            (personal.guardianRelationship?.trim().isNotEmpty ?? false) ==
                false)) {
      _showError('Completa los datos de contacto del tutor.');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await InscriptionService.instance.signIn(_formData);

      if (!mounted) return;
      switch (result) {
        case Success<
          MemberInscriptionError,
          (String clientUid, String? checkoutUrl)
        >(
          :final result,
        ):
          if (_isReturningMember) {
            await showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cuenta creada'),
                content: const Text(
                  'Acude al gimnasio dentro de los próximos 4 días para que '
                  'recepción valide tu cuenta. De lo contrario, será bloqueada.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            );
            if (!mounted) return;
          } else {
            bool? urlLaunched;
            if (result.$2 != null) {
              urlLaunched = await launchUrl(Uri.parse(result.$2!));
            }

            if (!mounted) return;
            final message = (urlLaunched != null && !urlLaunched)
                ? "Cuenta creada. Completa tu pago en Mercado Pago."
                : "Registro completado. Tu sesión está iniciada.";

            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(message)));
          }
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (_) => false,
          );
        case Error<
          MemberInscriptionError,
          (String clientUid, String? checkoutUrl)
        >(
          :final errorType,
          :final exception,
        ):
          _showError(errorType.message);
          print("The exception is");
          print(exception);
      }
    } catch (e) {
      _showError('No se pudo completar el registro: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final names = _isReturningMember
        ? const [
            'Inscripción previa',
            'Validación de cuenta',
            'Datos personales',
            'Documentos',
            'Plan de entrenamiento',
          ]
        : const [
            'Inscripción previa',
            'Datos personales',
            'Documentos',
            'Plan de entrenamiento',
            'Resumen de compra',
            'Método de pago',
          ];
    final subtitles = _isReturningMember
        ? const [
            'Selecciona la opción que mejor responda la siguiente pregunta: ¿ya estás inscrito al gimnasio?',
            'Antes de continuar, toma en cuenta el plazo para validar tu cuenta.',
            'Confirma tus datos para crear tu cuenta.',
            'Sube imágenes claras de los documentos requeridos. Menores de edad: incluye tu CURP.',
            'Como ya te habías inscrito anteriormente, el sistema lo tiene presente. Selecciona tu plan de entrenamiento.',
          ]
        : const [
            'Selecciona la opción que mejor responda la siguiente pregunta: ¿ya estás inscrito al gimnasio?',
            'Introduce tu información para comenzar con tu inscripción al gimnasio.',
            'Sube imágenes claras de los documentos requeridos. Menores de edad: incluye tu CURP.',
            'Selecciona la opción de entrenamiento que mejor se adapte a ti.',
            'Revisa los beneficios y el total.',
            'Elige cómo realizarás tu pago.',
          ];
    final personal = _formData.personalData;
    return RegistrationScaffold(
      stepIndex: _step + 1,
      totalSteps: _totalSteps,
      stepName: names[_step],
      nextStepName: _step < names.length - 1 ? names[_step + 1] : null,
      title: names[_step],
      subtitle: subtitles[_step],
      isLoading: _loading,
      onBack: _requestExit,
      bottomActions: _buildBottomActions(),
      child: PageView(
        controller: _pages,
        physics: const NeverScrollableScrollPhysics(),
        children: _isReturningMember
            ? [
                RegisterPreviousInscriptionScreen(
                  data: _formData.previousInscriptionData,
                  onDataChanged: _updatePreviousInscriptionData,
                  onContinue: () => _goToStep(1),
                  showContinueButton: false,
                ),
                RegisterAccountValidationNoticeScreen(
                  onContinue: () => _goToStep(2),
                  showContinueButton: false,
                ),
                RegisterPersonalDataScreen(
                  initialData: personal,
                  formKey: _personalDataFormKey,
                  showContinueButton: false,
                  onChanged: _markPersonalDataChanged,
                  onContinue: (data) {
                    _updatePersonalData(data);
                    _goToStep(3);
                  },
                ),
                if (personal == null)
                  const SizedBox.shrink()
                else
                  RegisterIdScreen(
                    personalData: personal,
                    data: _formData.idData,
                    onDataChanged: _updateIdData,
                    onContinue: () => _goToStep(4),
                    showContinueButton: false,
                  ),
                RegisterPlanSelectionScreen(
                  plans: _membershipPlans,
                  isLoading: _isLoadingMembershipPlans,
                  loadError: _membershipPlanLoadError,
                  onRetry: _loadActiveMembershipPlans,
                  data: _formData.planSelectionData,
                  onDataChanged: _updatePlanData,
                  onContinue: _complete,
                  showContinueButton: false,
                ),
              ]
            : [
                RegisterPreviousInscriptionScreen(
                  data: _formData.previousInscriptionData,
                  onDataChanged: _updatePreviousInscriptionData,
                  onContinue: () => _goToStep(1),
                  showContinueButton: false,
                ),
                RegisterPersonalDataScreen(
                  initialData: personal,
                  formKey: _personalDataFormKey,
                  showContinueButton: false,
                  onChanged: _markPersonalDataChanged,
                  onContinue: (data) {
                    _updatePersonalData(data);
                    _goToStep(2);
                  },
                ),
                if (personal == null)
                  const SizedBox.shrink()
                else
                  RegisterIdScreen(
                    personalData: personal,
                    data: _formData.idData,
                    onDataChanged: _updateIdData,
                    onContinue: () => _goToStep(3),
                    showContinueButton: false,
                  ),
                RegisterPlanSelectionScreen(
                  plans: _membershipPlans,
                  isLoading: _isLoadingMembershipPlans,
                  loadError: _membershipPlanLoadError,
                  onRetry: _loadActiveMembershipPlans,
                  data: _formData.planSelectionData,
                  onDataChanged: _updatePlanData,
                  onContinue: () => _goToStep(4),
                  showContinueButton: false,
                ),
                RegisterPaymentSummaryScreen(
                  plans: _membershipPlans,
                  isLoading: _isLoadingMembershipPlans,
                  loadError: _membershipPlanLoadError,
                  onRetry: _loadActiveMembershipPlans,
                  data: _formData.planSelectionData,
                  onContinue: () => _goToStep(5),
                  showContinueButton: false,
                ),
                RegisterPaymentSelectionScreen(
                  data: _formData.paymentSelectionData,
                  onDataChanged: _updatePaymentData,
                  onContinue: _complete,
                  showContinueButton: false,
                ),
              ],
      ),
    );
  }
}
