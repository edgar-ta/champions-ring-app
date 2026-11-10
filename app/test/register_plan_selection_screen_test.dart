import 'package:champions_ring_app/core/models/core_date.dart';
import 'package:champions_ring_app/core/models/core_membership_plan.dart';
import 'package:champions_ring_app/features/inscription/models/member_inscription_data.dart';
import 'package:champions_ring_app/features/inscription/screens/register_payment_summary_screen.dart';
import 'package:champions_ring_app/features/inscription/screens/register_plan_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders database plans and returns the selected plan uid', (
    tester,
  ) async {
    MemberInscription_PlanSelectionData? selectedData;
    var continued = false;
    const plan = CoreMembershipPlan(
      uid: 'membership-plan-week',
      name: 'Plan semanal',
      cost: 180,
      benefits: 'Acceso a clases',
      duration: CoreMembershipPlanDuration.oneWeek,
      creationDate: CoreDate.ofServerControlledDate(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 500,
                child: RegisterPlanSelectionScreen(
                  plans: const [plan],
                  isLoading: false,
                  loadError: null,
                  onRetry: () {},
                  data: selectedData,
                  onDataChanged: (data) => setState(() => selectedData = data),
                  onContinue: () => continued = true,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Plan semanal'), findsOneWidget);
    expect(find.text('\$180'), findsOneWidget);
    expect(find.text('Acceso a clases'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'CONTINUAR'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Plan semanal'));
    await tester.pump();

    expect(selectedData?.membershipPlanUid, 'membership-plan-week');
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'CONTINUAR'),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('CONTINUAR'));
    expect(continued, isTrue);
  });

  testWidgets('summarizes the selected database plan and its price', (
    tester,
  ) async {
    const plan = CoreMembershipPlan(
      uid: 'membership-plan-month',
      name: 'Plan mensual',
      cost: 600,
      benefits: 'Acceso mensual',
      duration: CoreMembershipPlanDuration.oneMonth,
      creationDate: CoreDate.ofServerControlledDate(),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 500,
              child: RegisterPaymentSummaryScreen(
                plans: [plan],
                isLoading: false,
                loadError: null,
                onRetry: _noOp,
                data: MemberInscription_PlanSelectionData(
                  membershipPlanUid: 'membership-plan-month',
                ),
                onContinue: _noOp,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Plan mensual'), findsOneWidget);
    expect(find.text('Acceso mensual'), findsOneWidget);
    expect(find.text('\$600 MXN'), findsOneWidget);
    expect(find.text('\$120 MXN'), findsOneWidget);
    expect(find.text('\$720 MXN'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'CONTINUAR'),
          )
          .onPressed,
      isNotNull,
    );
  });
}

void _noOp() {}
