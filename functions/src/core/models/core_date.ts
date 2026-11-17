import {FieldValue, Timestamp} from "firebase-admin/firestore";

/** Representa una fecha compatible con las escrituras de Firestore. */
export class CoreDate {
  /** Inicializa la fecha con una única representación. */
  private constructor(
    readonly dateTime: Date | null = null,
    readonly timestamp: Timestamp | null = null,
    readonly fieldValue: FieldValue | null = null,
  ) {}

  /**
   * Crea el valor a partir de una fecha de JavaScript.
   * @param {Date} value Fecha local.
   * @return {CoreDate} Fecha compatible con Firestore.
   */
  static fromDateTime(value: Date): CoreDate {
    return new CoreDate(value);
  }

  /**
   * Crea el valor a partir de un Timestamp de Firestore.
   * @param {Timestamp} value Timestamp existente.
   * @return {CoreDate} Fecha compatible con Firestore.
   */
  static fromTimestamp(value: Timestamp): CoreDate {
    return new CoreDate(null, value);
  }

  /**
   * Crea el sentinel que Firestore resuelve con la hora de escritura.
   * @return {CoreDate} Fecha del servidor.
   */
  static ofWriteTime(): CoreDate {
    return new CoreDate(null, null, FieldValue.serverTimestamp());
  }

  /**
   * Crea una fecha cuyo valor se controla desde el servidor.
   * @return {CoreDate} Fecha controlada por el servidor.
   */
  static ofServerControlledDate(): CoreDate {
    return new CoreDate();
  }

  /**
   * Convierte el valor al tipo aceptado por una escritura de Firestore.
   * @return {Timestamp | FieldValue} Valor para Firestore.
   */
  toFirebaseValue(): Timestamp | FieldValue {
    if (this.fieldValue !== null) {
      return this.fieldValue;
    }

    if (this.timestamp !== null) {
      return this.timestamp;
    }

    return this.dateTime !== null ?
      Timestamp.fromDate(this.dateTime) :
      Timestamp.now();
  }
}
