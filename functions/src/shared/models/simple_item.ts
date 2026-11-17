/** Artículo sencillo usado para crear una preferencia de pago. */
export class SimpleItem {
  /** Crea un artículo con los datos del producto y su precio. */
  constructor(
    readonly uid: string,
    readonly productId: string,
    readonly title: string,
    readonly quantity: number,
    readonly unitPrice: number
  ) {
  }
}
