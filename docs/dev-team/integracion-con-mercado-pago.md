# Integración con Mercado Pago

El proyecto consta de dos integraciones, `Champions Ring Integration - Orders` y `Champions Ring Integration - Subscriptions`.

**Versión 2.0.0**

## Clasificación de Cambios

- **Cambios mayores**
  - Añadir una nueva integración.
  - Añadir un nuevo tipo de notificaciones admitidas en el webhook de una integración.
  - Añadir un nuevo protocolo de respuesta a una integración.
  - Añadir una plantilla de identificación de una notificación a un protocolo de respuesta.
  - Añadir a un protocolo de respuesta una acción que guarde o actualice atributos en la base de datos
  - Eliminar de un protocolo de respuesta una acción a realizar que guarde o actualice atributos obligatorios en la base de datos
  - Otros cambios no compatibles hacia atrás en las acciones a realizar de un protocolo de respuesta
- **Cambios menores**
  - Eliminar una integración.
  - Eliminar un tipo de notificaciones admitidas en el webhook de una integración.
  - Eliminar un protocolo de respuesta de una integración.
  - Eliminar una plantilla de identificación de una notificación de un protocolo de respuesta.
  - Eliminar de un protocolo de respuesta una acción a realizar que guarde o actualice atributos opcionales en la base de datos
  - Otros cambios compatibles hacia atrás en las acciones a realizar de un protocolo de respuesta
- **Parches**
  - Cambios en el formato del documento

## Consideraciones Importantes

Todo nuevo protocolo debe ser asociado a una ID ascendente. Los protocolos no pueden reutilizar IDs menores o iguales a la ID más alta utilizada hasta el momento.

Asimismo, toda nueva plantilla debe ser asociada a una ID ascendente. Las plantillas no pueden reutilizar IDs menores o iguales a la ID más alta utilizada hasta el momento.

Si el webhook recibe una notificación de un tipo no reconocido (esto es, que no está incluido en ninguna de las listas de tipos de notificaciones a procesar en las integraciones de esta especificación), se deberá retornar un estatus 501.

## Integración "Champions Ring Integration - Orders"

**API utilizada:** Checkout Pro - Orders API

**Tipos de notificaciones que debe procesar el webhook:**
- `order`

### Protocolos de Respuesta a los Eventos

#### Protocolo 1: Order Aprobada

**¿Cómo identificarlo?**:

```ts
type PlantillasProtocolo1 = Plantilla1;

type Plantilla1 = {
    status: "processed" | "created";
    status_detail: "accredited";
}
```

**Acciones a Realizar:**

- Recuperar el registro almacenado en el backend de Mercado Pago por medio del endpoint `GET /v1/orders/{id}` donde `id` es el identificador dado en el atributo `data.id` de la notificación recibida. A este registro se le conocerá como "order".
- Obtener el documento en la colección `payments` cuya id coincide con el valor del atributo `external_reference` de la notificación recibida. A este documento se le conocerá como "pago".
- Si el estatus y detalle de estatus obtenidos en los atributos `status` y `status_detail` de la order, respectivamente, coinciden con el patrón descrito en las plantillas de este protocolo, continuar con los pasos subsecuentes. Si no, proceder con las acciones correspondientes al estatus y detalle de estatus verdaderos de la order.
- Guardar o reemplazar el valor del atributo `status` del pago con el valor `"approved"`.
- Guardar en el atributo `approvalDate` del pago el valor de la fecha actual.
- Si la lista en el atributo `items` de la order incluye un objeto cuyo atributo `external_code` coincide con el valor de la constante `INSCRIPTION_PRODUCT_ID`:
  - Crear una referencia hacia el documento en la colección `members` cuya id coincide con el último segmento de la URI almacenada en el atributo `payerRef` del pago. A este documento se le conocerá como "miembro".
  - Reemplazar el valor del atributo `inscriptionPaid` del miembro con el valor `true`.
- Responder con código 200.

#### Protocolo 2: Order Pendiente

**¿Cómo identificarlo?**:

```ts
type PlantillasProtocolo2 = Plantilla2 | Plantilla3;

type Plantilla2 = {
    status: "processing";
    status_detail: "in_process" | "pending_review_manual";
}

type Plantilla3 = {
    status: "action_required";
    status_detail: "waiting_capture";
}
```

**Acciones a Realizar:**

- Recuperar el registro almacenado en el backend de Mercado Pago por medio del endpoint `GET /v1/orders/{id}` donde `id` es el identificador dado en el atributo `data.id` de la notificación recibida. A este registro se le conocerá como "order".
- Obtener el documento en la colección `payments` cuya id coincide con el valor del atributo `external_reference` de la notificación recibida. A este documento se le conocerá como "pago".
- Si el estatus y detalle de estatus obtenidos en los atributos `status` y `status_detail` de la order, respectivamente, coinciden con el patrón descrito en las plantillas de este protocolo, continuar con los pasos subsecuentes. Si no, proceder con las acciones correspondientes al estatus y detalle de estatus verdaderos de la order.
- Guardar o reemplazar el valor del atributo `status` del pago con el valor `"processing"`.
- Responder con código 200.

#### Protocolo 3: Order Reembolsada

**¿Cómo identificarlo?**:

```ts
type PlantillasProtocolo3 = Plantilla4 | Plantilla5;

type Plantilla4 = {
    status: "refunded";
    status_detail: "refunded";
}

type Plantilla5 = {
    status: "processed";
    status_detail: "partially_refunded";
}
```

**Acciones a Realizar:**

- Recuperar el registro almacenado en el backend de Mercado Pago por medio del endpoint `GET /v1/orders/{id}` donde `id` es el identificador dado en el atributo `data.id` de la notificación recibida. A este registro se le conocerá como "order".
- Obtener el documento en la colección `payments` cuya id coincide con el valor del atributo `external_reference` de la notificación recibida. A este documento se le conocerá como "pago".
- Si el estatus y detalle de estatus obtenidos en los atributos `status` y `status_detail` de la order, respectivamente, coinciden con el patrón descrito en las plantillas de este protocolo, continuar con los pasos subsecuentes. Si no, proceder con las acciones correspondientes al estatus y detalle de estatus verdaderos de la order.
- Reemplazar el valor del atributo `status` del pago con el valor `"refunded"`.
- Responder con código 200.

#### Protocolo 4: Order Rechazada

**¿Cómo identificarlo?**:

```ts
type PlantillasProtocolo4 = Plantilla6;

type Plantilla6 = {
    status: "failed";
    status_detail: "high_risk" | "rejected_by_issuer" | "insufficient_amount" | "invalid_card_token" | "processing_error" | string;
}
```

**Acciones a Realizar:**

- Recuperar el registro almacenado en el backend de Mercado Pago por medio del endpoint `GET /v1/orders/{id}` donde `id` es el identificador dado en el atributo `data.id` de la notificación recibida. A este registro se le conocerá como "order".
- Obtener el documento en la colección `payments` cuya id coincide con el valor del atributo `external_reference` de la notificación recibida. A este documento se le conocerá como "pago".
- Si el estatus y detalle de estatus obtenidos en los atributos `status` y `status_detail` de la order, respectivamente, coinciden con el patrón descrito en las plantillas de este protocolo, continuar con los pasos subsecuentes. Si no, proceder con las acciones correspondientes al estatus y detalle de estatus verdaderos de la order.
- Reemplazar el valor del atributo `status` del pago con el valor `"rejected"`.
- Guardar en el atributo `rejectionDetail` del pago el valor del atributo `status_detail` de la order.
- Responder con código 200.

#### Protocolo 5: Order Cancelada

**¿Cómo identificarlo?**:

```ts
type PlantillasProtocolo5 = Plantilla7;

type Plantilla7 = {
    status: "canceled";
    status_detail: "canceled";
}
```

**Acciones a Realizar:**

- Recuperar el registro almacenado en el backend de Mercado Pago por medio del endpoint `GET /v1/orders/{id}` donde `id` es el identificador dado en el atributo `data.id` de la notificación recibida. A este registro se le conocerá como "order".
- Obtener el documento en la colección `payments` cuya id coincide con el valor del atributo `external_reference` de la notificación recibida. A este documento se le conocerá como "pago".
- Si el estatus y detalle de estatus obtenidos en los atributos `status` y `status_detail` de la order, respectivamente, coinciden con el patrón descrito en las plantillas de este protocolo, continuar con los pasos subsecuentes. Si no, proceder con las acciones correspondientes al estatus y detalle de estatus verdaderos de la order.
- Reemplazar el valor del atributo `status` del pago con el valor `"canceled"`.
- Responder con código 200.

### ¿Bajo qué condiciones le será permitido el acceso a su cuenta al usuario miembro?

- Si han pasado menos de tres días desde que creó su cuenta de miembro.
- Si el atributo `inscriptionPaid` del documento correspondiente al miembro es verdadero.
- Si el pago asociado a la renovación más reciente del usuario está en estado `processed`.