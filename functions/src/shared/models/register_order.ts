export interface RegisterOrderItem {
  productId: string;
  title: string;
  quantity: number;
  unitPrice: number;
  description?: string;
  categoryId?: string;
  pictureUrl?: string;
  type?: string;
  warranty?: boolean;
  unitMeasure?: string;
}

export interface RegisterOrderPayer {
  email: string;
  firstName?: string;
  lastName?: string;
  identification?: {
    type: string;
    number: string;
  };
  phone?: {
    area_code?: string;
    number?: string;
  };
  address?: {
    street_name?: string;
    street_number?: string;
    zip_code?: string;
    neighborhood?: string;
    state?: string;
    city?: string;
    complement?: string;
    country?: string;
  };
}

export interface RegisterOrderShipment {
  mode: "me2" | "custom" | "not_specified";
  localPickup?: boolean;
  cost?: number;
  freeShipping?: boolean;
  address?: {
    zipCode?: string;
    streetName?: string;
    streetNumber?: string;
    floor?: string;
    apartment?: string;
    neighborhood?: string;
    city?: string;
    state?: string;
    complement?: string;
    country?: string;
  };
}

export interface RegisterOrderInput {
  paymentUid: string;
  items: RegisterOrderItem[];
  payer?: RegisterOrderPayer;
  additionalInfo?: Record<string, unknown>;
  shipment?: RegisterOrderShipment;
  integrationData?: {
    integratorId?: string;
    platformId?: string;
    corporationId?: string;
  };
  paymentMethod?: {
    maxInstallments?: number;
    notAllowedIds?: string[];
    notAllowedTypes?: string[];
  };
}

export interface RegisteredOrder {
  id: string;
  checkoutUrl: string;
}
