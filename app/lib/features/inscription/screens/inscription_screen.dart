import 'package:flutter/material.dart';

import '../../../core/models/core_payment.dart' show CorePaymentType;
import '../../../core/models/core_membership_plan.dart';
import '../../../core/repositories/core_membership_plan_repository.dart';
import '../../../core/services/mercado_pago_checkout_service.dart';
import '../../../core/utils/result.dart';
import '../models/member_inscription_data.dart';
import '../services/inscription_service.dart';
import '../widgets/registration_scaffold.dart';
import 'register_account_validation_notice_screen.dart';
import 'register_id_screen.dart';
import 'register_payment_selection_screen.dart';
import 'register_payment_summary_screen.dart';
import 'register_personal_data_screen.dart';
import 'register_plan_selection_screen.dart';
import 'register_previous_inscription_screen.dart';
import '../../home/screens/home_screen.dart';

import 'package:cloud_functions/cloud_functions.dart';

/// Contenedor del wizard: mantiene los datos de cada paso en UserFormData.
class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  static const _maxDocumentBytes = 20 * 1024 * 1024;
  final _pages = PageController();
  late MemberInscriptionData _formData;
  int _step = 0;
  bool _loading = false;
  List<CoreMembershipPlan>? _membershipPlans;
  bool _isLoadingMembershipPlans = false;
  Object? _membershipPlanLoadError;

  bool get _isReturningMember =>
      _formData.previousInscriptionData?.previouslySignedIn == true;

  int get _totalSteps => _isReturningMember ? 5 : 6;

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

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      _goToStep(_step - 1);
    }
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
        case Success<MemberInscriptionError, String>():
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
                    child: const Text('ENTENDIDO'),
                  ),
                ],
              ),
            );
            if (!mounted) return;
          } else {
            final payment = _formData.paymentSelectionData!;
            final plan = _formData.planSelectionData!;

            String? checkoutError;

            if (payment.paymentMethod == CorePaymentType.mercadoPago) {
              try {
                await MercadoPagoCheckoutService.open(plan.membershipPlanUid);
              } on FirebaseFunctionsException catch (e) {
                checkoutError = e.message ?? e.code;
                debugPrint(
                  'Error al crear el checkout: ${e.code} ${e.message}',
                );
              } catch (e) {
                checkoutError = '$e';
                debugPrint('Error al crear el checkout: $e');
              }
            }

            if (!mounted) return;

            final message = checkoutError != null
                ? 'Tu cuenta se creó, pero no se pudo abrir el pago '
                      '($checkoutError). Inicia sesión e intenta pagar nuevamente.'
                : payment.paymentMethod == CorePaymentType.mercadoPago
                ? 'Cuenta creada. Completa tu pago en Mercado Pago.'
                : 'Registro completado. Tu sesión está iniciada.';

            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(message)));
          }
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (_) => false,
          );
        case Error<MemberInscriptionError, String>(
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
            'Como ya te habías inscrito anteriormente, el sistema lo tiene presente. Confirma tus datos para crear tu cuenta.',
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
      onBack: _back,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: PageView(
          controller: _pages,
          physics: const NeverScrollableScrollPhysics(),
          children: _isReturningMember
              ? [
                  RegisterPreviousInscriptionScreen(
                    data: _formData.previousInscriptionData,
                    onDataChanged: _updatePreviousInscriptionData,
                    onContinue: () => _goToStep(1),
                  ),
                  RegisterAccountValidationNoticeScreen(
                    onContinue: () => _goToStep(2),
                  ),
                  RegisterPersonalDataScreen(
                    initialData: personal,
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
                    ),
                  RegisterPlanSelectionScreen(
                    plans: _membershipPlans,
                    isLoading: _isLoadingMembershipPlans,
                    loadError: _membershipPlanLoadError,
                    onRetry: _loadActiveMembershipPlans,
                    data: _formData.planSelectionData,
                    onDataChanged: _updatePlanData,
                    onContinue: _complete,
                  ),
                ]
              : [
                  RegisterPreviousInscriptionScreen(
                    data: _formData.previousInscriptionData,
                    onDataChanged: _updatePreviousInscriptionData,
                    onContinue: () => _goToStep(1),
                  ),
                  RegisterPersonalDataScreen(
                    initialData: personal,
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
                    ),
                  RegisterPlanSelectionScreen(
                    plans: _membershipPlans,
                    isLoading: _isLoadingMembershipPlans,
                    loadError: _membershipPlanLoadError,
                    onRetry: _loadActiveMembershipPlans,
                    data: _formData.planSelectionData,
                    onDataChanged: _updatePlanData,
                    onContinue: () => _goToStep(4),
                  ),
                  RegisterPaymentSummaryScreen(
                    plans: _membershipPlans,
                    isLoading: _isLoadingMembershipPlans,
                    loadError: _membershipPlanLoadError,
                    onRetry: _loadActiveMembershipPlans,
                    data: _formData.planSelectionData,
                    onContinue: () => _goToStep(5),
                  ),
                  RegisterPaymentSelectionScreen(
                    data: _formData.paymentSelectionData,
                    onDataChanged: _updatePaymentData,
                    onContinue: _complete,
                  ),
                ],
        ),
      ),
    );
  }
}
