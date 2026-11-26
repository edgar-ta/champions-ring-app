import { doc, getDoc, getDocs, orderBy, query, Timestamp, where } from "firebase/firestore";

import { clientsCollection, paymentsCollection } from "@/app/core/firebase/collections";
import type { Client } from "@/app/core/models/client";
import { toDate } from "@/app/core/utils/format";
import type { ApprovedPayment, PaymentRepository } from "./payment-repository";

export const firebasePaymentRepository: PaymentRepository = {
  async listApprovedSince(since) {
    // Solo los pagos aprobados tienen approvalDate: efectivo y transferencia al registrarlos,
    // Mercado Pago cuando el servidor lo confirma.
    const snapshot = await getDocs(query(
      paymentsCollection(),
      where("approvalDate", ">=", Timestamp.fromDate(since)),
      orderBy("approvalDate", "desc"),
    ));
    const payments = snapshot.docs.map(document => document.data()).filter(payment => payment.deletionDate == null);

    // Se busca una sola vez el nombre de cada cliente, aunque haya pagado varias veces.
    const clientNames = new Map<string, Promise<string | null>>();
    const nameOf = (uid: string) => {
      if (!clientNames.has(uid)) {
        clientNames.set(uid, getDoc(doc(clientsCollection(), uid))
          .then(result => { const client: Client | undefined = result.data(); return client ? `${client.name} ${client.lastName}`.trim() : null; })
          .catch(() => null));
      }
      return clientNames.get(uid)!;
    };

    return Promise.all(payments.map(async (payment): Promise<ApprovedPayment> => ({
      uid: payment.uid,
      type: payment.type,
      amount: Number(payment.amount) || 0,
      approvalDate: toDate(payment.approvalDate) ?? since,
      payerName: payment.payerRef ? await nameOf(payment.payerRef.id) : null,
    })));
  },
};
