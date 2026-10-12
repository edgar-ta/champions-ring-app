import 'package:flutter/material.dart';

import '../../../core/utils/result.dart';
import '../models/user_inscription_data.dart';
import '../services/inscription_service.dart';
import '../widgets/registration_scaffold.dart';
import 'register_id_screen.dart';
import 'register_payment_selection_screen.dart';
import 'register_payment_summary_screen.dart';
import 'register_personal_data_screen.dart';
import 'register_plan_selection_screen.dart';
import 'register_waiver_agreement_screen.dart';
import '../../home/screens/home_screen.dart';

/// Contenedor del wizard: mantiene los datos de cada paso en UserFormData.
class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  static const _maxDocumentBytes = 20 * 1024 * 1024;
  final _pages = PageController();
  late UserInscriptionData _formData;
  int _step = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _formData = UserInscriptionData();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step > 5) return;
    setState(() => _step = step);
    _pages.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      _goToStep(_step - 1);
    }
  }

  void _updatePersonalData(UserInscription_PersonalData data) => setState(() {
    final previousPersonalData = _formData.personalData;
    final legalAgeStatusChanged =
        previousPersonalData != null &&
        previousPersonalData.isOfLegalAge != data.isOfLegalAge;

    _formData = _formData.copyWith(
      personalData: data,
      clearIdData: legalAgeStatusChanged,
    );
  });

  void _updateIdData(UserInscription_IdData data) =>
      setState(() => _formData = _formData.copyWith(idData: data));

  void _updateWaiverData(UserInscription_WaiverAgreementData? data) => setState(
    () => _formData = (data == null
        ? _formData.copyWith(clearWaiverAgreementData: true)
        : _formData.copyWith(waiverAgreementData: data)),
  );

  void _updatePlanData(UserInscription_PlanSelectionData data) => setState(
    () => _formData = _formData.copyWith(
      planSelectionData: data,
      clearPaymentSelectionData: true,
    ),
  );

  void _updatePaymentData(UserInscription_PaymentSelectionData data) =>
      setState(
        () => _formData = _formData.copyWith(paymentSelectionData: data),
      );

  Future<void> _complete() async {
    final personal = _formData.personalData;
    final id = _formData.idData;
    final waiver = _formData.waiverAgreementData;
    final plan = _formData.planSelectionData;
    final payment = _formData.paymentSelectionData;
    if (personal == null ||
        id == null ||
        id.ineFrontBytes == null ||
        id.ineFrontFormat == null ||
        id.ineBackBytes == null ||
        id.ineBackFormat == null ||
        waiver == null ||
        plan == null ||
        payment == null) {
      _showError('Completa todos los pasos del registro.');
      return;
    }
    if (personal.photoBytes.length > 5 * 1024 * 1024) {
      _showError('La foto de perfil no debe superar 5 MB.');
      return;
    }
    final documentSizes = [
      id.ineFrontBytes!.length,
      id.ineBackBytes!.length,
      waiver.signatureBytes.length,
    ];
    if (documentSizes.any((size) => size > _maxDocumentBytes)) {
      _showError('La INE y la firma deben pesar como máximo 20 MB cada una.');
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
      final result = await SignupService.instance.signUp(_formData);

      if (!mounted) return;
      switch (result) {
        case Success<UserInscriptionError, String>():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registro completado. Tu sesión está iniciada.'),
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (_) => false,
          );
        case Error<UserInscriptionError, String>(:final errorType):
          _showError(errorType.message);
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
    const names = [
      'Datos personales',
      'INE',
      'Responsiva',
      'Plan de entrenamiento',
      'Resumen de compra',
      'Método de pago',
    ];
    final personal = _formData.personalData;
    return RegistrationScaffold(
      stepIndex: _step + 1,
      totalSteps: names.length,
      stepName: names[_step],
      nextStepName: _step < names.length - 1 ? names[_step + 1] : null,
      title: names[_step],
      subtitle: const [
        'Introduce tu información para comenzar con tu inscripción al gimnasio.',
        'Sube una imagen clara de tu INE o la de tu tutor legal (menores de edad).',
        'Revisa y firma la carta responsiva. Menores de edad: solicitar firma de su tutor legal.',
        'Selecciona la opción de entrenamiento que mejor se adapte a ti.',
        'Revisa los beneficios y el total.',
        'Elige cómo realizarás tu pago.',
      ][_step],
      isLoading: _loading,
      onBack: _back,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: PageView(
          controller: _pages,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            RegisterPersonalDataScreen(
              initialData: personal,
              onContinue: (data) {
                _updatePersonalData(data);
                _goToStep(1);
              },
            ),
            if (personal == null)
              const SizedBox.shrink()
            else
              RegisterIdScreen(
                personalData: personal,
                data: _formData.idData,
                onDataChanged: _updateIdData,
                onContinue: () => _goToStep(2),
              ),
            RegisterWaiverAgreementScreen(
              data: _formData.waiverAgreementData,
              onDataChanged: _updateWaiverData,
              onContinue: () => _goToStep(3),
            ),
            RegisterPlanSelectionScreen(
              data: _formData.planSelectionData,
              onDataChanged: _updatePlanData,
              onContinue: () => _goToStep(4),
            ),
            RegisterPaymentSummaryScreen(
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
