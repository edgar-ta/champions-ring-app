import {Timestamp} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import type {CallableRequest} from "firebase-functions/v2/https";
import {
  CoreMembershipPlanRepository,
} from "../../core/repositories/core_membership_plan_repository.js";
import {
  CoreMemberRepository,
} from "../../core/repositories/core_member_repository.js";
import {
  CorePaymentRepository,
} from "../../core/repositories/core_payment_repository.js";
import {MercadoPagoPayment} from "../../shared/models/payment.js";
import {CoreDate} from "../../core/models/core_date.js";
import {
  MP_ACCESS_TOKEN,
  MP_TIMEOUT_MS,
  NOTIFICATION_URL,
  REGISTRATION_FEE,
  REUSE_WINDOW_MS,
  RETURN_URL,
  USE_SANDBOX,
  db,
  REGION,
} from "../../core/utils/constants.js";

type MembershipCheckoutRequest = {
  membershipPlanUid?: unknown;
};

export const createMembershipCheckout = onCall(
  {region: REGION, secrets: [MP_ACCESS_TOKEN]},
  async (request: CallableRequest<MembershipCheckoutRequest>) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Debes iniciar sesión para pagar.",
      );
    }

    const memberUid = request.auth.uid;
    const membershipPlanUid = request.data?.membershipPlanUid;
    if (
      typeof membershipPlanUid !== "string" ||
      membershipPlanUid.trim() === ""
    ) {
      throw new HttpsError(
        "invalid-argument",
        "El identificador del plan de membresía no es válido.",
      );
    }

    const membershipPlanRepository = new CoreMembershipPlanRepository(db);
    const membershipPlan =
      await membershipPlanRepository.findById(membershipPlanUid);
    if (membershipPlan === undefined) {
      throw new HttpsError(
        "invalid-argument",
        "El identificador del plan de membresía no es válido.",
      );
    }

    const memberRepository = new CoreMemberRepository(db);
    const member = await memberRepository.findById(memberUid);
    if (member === undefined) {
      throw new HttpsError(
        "failed-precondition",
        "No existe el perfil del alumno.",
      );
    }

    const typeByDuration = {
      "1d": "day",
      "1w": "week",
      "1m": "month",
    } as const;
    const type = typeByDuration[membershipPlan.duration];
    const totalAmount = membershipPlan.cost + REGISTRATION_FEE;

    // Si hay un checkout reciente igual, se reutiliza (evita acumular
    // documentos "pending" cuando el usuario toca el botón varias veces).
    const recent = await db
      .collection("payments")
      .where("payerRef", "==", memberRepository.collection.doc(memberUid))
      .where("type", "==", "mercado-pago")
      .where("status", "==", "pending")
      .limit(10)
      .get();

    const reusable = recent.docs.find((doc) => {
      const data = doc.data();
      const createdAt =
        data.createdAt instanceof Timestamp ? data.createdAt.toMillis() : 0;
      return (
        data.amount === totalAmount &&
        typeof data.checkoutUrl === "string" &&
        Date.now() - createdAt < REUSE_WINDOW_MS
      );
    });

    if (reusable) {
      return {
        paymentId: reusable.id,
        checkoutUrl: reusable.data().checkoutUrl as string,
      };
    }

    // Se crea una referencia propia antes de contactar con Mercado Pago.
    const paymentRepository = new CorePaymentRepository(db);
    const paymentUid = paymentRepository.nextUid;
    const payment = new MercadoPagoPayment({
      uid: paymentUid,
      amount: membershipPlan.cost,
      currency: "MXN",
      creationDate: CoreDate.ofWriteTime(),
      payerRef: memberRepository.collection.doc(memberUid),
      checkoutUrl: "",
      status: "pending",
      preferenceId: "",
    });

    await paymentRepository.upsert(payment.toCorePayment());

    // await paymentRef.set({
    //   uid: memberUid,
    //   membershipType: type,
    //   membershipPlanId: membershipPlan.uid,
    //   membershipAmount: membershipPlan.cost,
    //   registrationFee,
    //   amount: totalAmount,
    //   currency: "MXN",
    //   status: "pending",
    //   provider: "mercadopago",
    //   processed: false,
    //   createdAt: FieldValue.serverTimestamp(),
    // });

    const items: Array<Record<string, unknown>> = [
      {
        id: "membership",
        title: membershipPlan.name,
        quantity: 1,
        currency_id: "MXN",
        unit_price: membershipPlan.cost,
      },
      {
        id: "registration",
        title: "Inscripción Champions Ring",
        quantity: 1,
        currency_id: "MXN",
        unit_price: REGISTRATION_FEE,
      },
    ];

    let response: Response;

    try {
      response = await fetch(
        "https://api.mercadopago.com/checkout/preferences",
        {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${MP_ACCESS_TOKEN.value()}`,
            "Content-Type": "application/json",
            "X-Idempotency-Key": paymentUid,
          },
          signal: AbortSignal.timeout(MP_TIMEOUT_MS),
          body: JSON.stringify({
            items,
            external_reference: paymentUid,
            metadata: {
              firebase_uid: memberUid,
              membership_type: type,
            },
            notification_url: NOTIFICATION_URL,
            // Mercado Pago EXIGE back_urls.success cuando se usa
            // auto_return; sin ellas rechaza la preferencia.
            back_urls: {
              success: `${RETURN_URL}/success`,
              pending: `${RETURN_URL}/pending`,
              failure: `${RETURN_URL}/failure`,
            },
            auto_return: "approved",
            statement_descriptor: "CHAMPIONS RING",
          }),
        },
      );
    } catch (error) {
      logger.error("No se pudo contactar a Mercado Pago", error);
      await paymentRepository.upsert(
        payment
          .copyWith({status: "checkout_creation_failed"})
          .toCorePayment(),
      );
      throw new HttpsError(
        "unavailable",
        "No fue posible conectar con Mercado Pago. Intenta de nuevo.",
      );
    }

    const result = (await response.json().catch(() => ({}))) as {
      id?: string;
      init_point?: string;
      sandbox_init_point?: string;
      message?: string;
    };

    if (!response.ok || !result.id || !result.init_point) {
      logger.error("Error al crear preferencia", {
        status: response.status,
        response: result,
      });

      await paymentRepository.upsert(
        payment
          .copyWith({status: "checkout_creation_failed"})
          .toCorePayment(),
      );

      throw new HttpsError("internal", "No fue posible iniciar el pago.");
    }

    // Mercado Pago siempre devuelve ambas URLs; el servidor decide cuál
    // usar para que la app nunca mande clientes reales al sandbox.
    const checkoutUrl = USE_SANDBOX ?
      (result.sandbox_init_point ?? result.init_point) :
      result.init_point;

    await paymentRepository.upsert(
      payment
        .copyWith({
          preferenceId: result.id,
          checkoutUrl: checkoutUrl,
        })
        .toCorePayment(),
    );

    return {
      paymentId: paymentUid,
      checkoutUrl,
    };
  },
);
