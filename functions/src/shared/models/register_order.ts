export interface MercadoPagoOrderItem {
  external_code?: string;
}

export interface MercadoPagoOrder {
  id: string;
  external_reference?: string;
  status?: string;
  status_detail?: string;
  items?: MercadoPagoOrderItem[];
}

type RegisterOrderShipmentAddress =
  NonNullable<RegisterOrderShipment["address"]>;
type RegisterOrderPaymentMethod =
  NonNullable<RegisterOrderInput["paymentMethod"]>;
type RegisterOrderIntegrationData =
  NonNullable<RegisterOrderInput["integrationData"]>;

type CreateOrderItem = Pick<
  RegisterOrderItem,
  "title" | "quantity" | "type" | "warranty"
> & {
  external_code: string;
  description?: RegisterOrderItem["description"];
  category_id?: RegisterOrderItem["categoryId"];
  picture_url?: RegisterOrderItem["pictureUrl"];
  unit_price: string;
  unit_measure?: RegisterOrderItem["unitMeasure"];
};

export interface CreateOrderRequest {
  type: "online";
  processing_mode: "manual";
  capture_mode: "automatic_async";
  total_amount: string;
  currency: "MXN";
  external_reference: string;
  description: string;
  payer?: Pick<
    RegisterOrderPayer,
    "email" | "identification" | "phone" | "address"
  > & {
    first_name?: RegisterOrderPayer["firstName"];
    last_name?: RegisterOrderPayer["lastName"];
  };
  items: CreateOrderItem[];
  additional_info?: RegisterOrderInput["additionalInfo"];
  shipment?: {
    mode: RegisterOrderShipment["mode"];
    local_pickup?: RegisterOrderShipment["localPickup"];
    cost?: string;
    free_shipping?: RegisterOrderShipment["freeShipping"];
    address?: {
      zip_code?: RegisterOrderShipmentAddress["zipCode"];
      street_name?: RegisterOrderShipmentAddress["streetName"];
      street_number?: RegisterOrderShipmentAddress["streetNumber"];
    } & Pick<
      RegisterOrderShipmentAddress,
      | "floor"
      | "apartment"
      | "neighborhood"
      | "city"
      | "state"
      | "complement"
      | "country"
    >;
  };
  integration_data?: {
    integrator_id?: RegisterOrderIntegrationData["integratorId"];
    platform_id?: RegisterOrderIntegrationData["platformId"];
    corporation_id?: RegisterOrderIntegrationData["corporationId"];
  };
  config: {
    statement_descriptor: string;
    online: {
      callback_url: string;
      success_url: string;
      pending_url: string;
      failure_url: string;
      auto_return: "approved";
    };
    payment_method?: {
      max_installments?: RegisterOrderPaymentMethod["maxInstallments"];
      not_allowed_ids?: RegisterOrderPaymentMethod["notAllowedIds"];
      not_allowed_types?: RegisterOrderPaymentMethod["notAllowedTypes"];
    };
  };
}

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

export type OrderHandler = (order: MercadoPagoOrder) => Promise<void>;
