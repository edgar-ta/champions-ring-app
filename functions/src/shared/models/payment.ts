import type {DocumentReference} from "firebase-admin/firestore";
import {CoreDate} from "../../core/models/core_date.js";
import {
  CorePayment,
  type CorePaymentCurrency,
  type CorePaymentStatus,
} from "../../core/models/core_payment.js";

type PaymentData = {
  uid: string;
  amount: number;
  currency: CorePaymentCurrency;
  creationDate: CoreDate;
  approvalDate?: CoreDate;
  deletionDate?: CoreDate;
  payerRef?: DocumentReference;
};

type MercadoPagoPaymentData = {
  checkoutUrl: string;
  status: CorePaymentStatus;
  preferenceId: string;
};

type PaymentCopyWith = Partial<PaymentData & MercadoPagoPaymentData>;

/** Datos de pago compartidos por todos los métodos. */
export abstract class Payment {
  readonly uid: string;
  readonly amount: number;
  readonly currency: CorePaymentCurrency;
  readonly approvalDate?: CoreDate;
  readonly creationDate: CoreDate;
  readonly deletionDate?: CoreDate;
  readonly payerRef?: DocumentReference;

  /**
   * Inicializa los datos comunes del pago.
   * @param {PaymentData} data Datos comunes del pago.
   */
  protected constructor(data: PaymentData) {
    this.uid = data.uid;
    this.amount = data.amount;
    this.currency = data.currency;
    this.approvalDate = data.approvalDate;
    this.creationDate = data.creationDate;
    this.deletionDate = data.deletionDate;
    this.payerRef = data.payerRef;
  }

  /** Devuelve una copia con los valores proporcionados reemplazados. */
  abstract copyWith(data?: PaymentCopyWith): Payment;

  abstract toCorePayment(): CorePayment;
}

/** Pago de Mercado Pago con URL de checkout e ID de preferencia. */
export class MercadoPagoPayment extends Payment {
  readonly checkoutUrl: string;
  readonly status: CorePaymentStatus;
  readonly preferenceId: string;

  /**
   * Crea un pago de Mercado Pago.
   * @param {object} data Datos comunes y específicos del pago de Mercado Pago.
   */
  constructor(data: PaymentData & MercadoPagoPaymentData) {
    super(data);
    this.checkoutUrl = data.checkoutUrl;
    this.status = data.status;
    this.preferenceId = data.preferenceId;
  }

  /**
   * Devuelve una copia del pago con los valores proporcionados reemplazados.
   * @param {PaymentCopyWith} data Valores que reemplazarán los actuales.
   * @return {MercadoPagoPayment} Copia actualizada del pago.
   */
  copyWith(data: PaymentCopyWith = {}): MercadoPagoPayment {
    return new MercadoPagoPayment({
      uid: data.uid ?? this.uid,
      amount: data.amount ?? this.amount,
      currency: data.currency ?? this.currency,
      approvalDate: data.approvalDate ?? this.approvalDate,
      creationDate: data.creationDate ?? this.creationDate,
      deletionDate: data.deletionDate ?? this.deletionDate,
      payerRef: data.payerRef ?? this.payerRef,
      checkoutUrl: data.checkoutUrl ?? this.checkoutUrl,
      status: data.status ?? this.status,
      preferenceId: data.preferenceId ?? this.preferenceId,
    });
  }

  /**
   * Convierte este pago al modelo principal.
   * @return {CorePayment} Modelo principal del pago.
   */
  toCorePayment(): CorePayment {
    return new CorePayment(
      this.uid,
      "mercado-pago",
      this.amount,
      this.currency,
      this.creationDate,
      this.approvalDate,
      this.payerRef,
      this.checkoutUrl,
      this.status,
      this.preferenceId,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      this.deletionDate
    );
  }
}
