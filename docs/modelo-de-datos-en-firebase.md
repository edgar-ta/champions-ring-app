# Modelo de Datos en Firebase

Versión 19.0.0

## Clasificación de Cambios
- Cambios mayores
  - Añadir, eliminar o renombrar colecciones
  - Añadir atributos no nulables
  - Eliminar atributos no nulables 
  - Renombrar atributos no nulables
  - Cambiar el tipo de dato de un atributo no nulo de forma no equivalente

- Cambios menores
  - Añadir atributos nulables
  - Eliminar atributos nulables 
  - Renombrar atributos nulables
  - Cambiar el tipo de dato de un atributo nulable

- Parches
  - Cambiar el tipo de dato de un atributo no nulable de forma equivalente (ej. double en vez de int)
  - Cambiar el tipo de dato de un atributo nulable de forma equivalente (ej. double en vez de int)
  - Cambios en la documentación o formato del documento

## Descripción del Modelo de Datos

```txt
clients
	uid: string
	name: string
	last_name: string
	email: string

	sample_class_date: timestamp?

members
	uid: string
	birth_date: timestamp
	phone: string
	photo_url: string?
	legal_data_are_theirs: boolean
	registration_payed: boolean

	membership_plan_ref: reference?

	guardian_name: string?
	guardian_phone: string?
	guardian_relationship: string?
	curp_url: string?
	curp_validated: boolean

	waiver_agreement_url: string
	ine_back_url: string
	ine_front_url: string

	ine_back_validated: boolean
	ine_front_validated: boolean
	waiver_agreement_validated: boolean

	creation_date: timestamp
	deletion_date: timestamp?

	renewals/
		start_date: timestamp
		end_date: timestamp
		membership_plan_ref: reference?
		payment_ref: reference
		amount: double

		creation_date: timestamp
		deletion_date: timestamp?

receptionists
	uid: string
	name: string
	last_name: string
	email: string

	creation_date: timestamp
	deletion_date: timestamp?

administrators
	uid: string
	name: string
	last_name: string
	email: string

	creation_date: timestamp
	deletion_date: timestamp?

membership_plans
	uid: string
	cost: double
	benefits: string
	duration: "1d" | "1w" | "1m"

	creation_date: timestamp
	deletion_date: timestamp?

payments
	uid: string
	type: "cash" | "direct-transfer" | "mercado-pago"

	amount: double
	currency: "MXN" | "USD"
	approval_date: timestamp?

	-- mercado-pago only
	checkout_url: string?
	status: ("approved" | "rejected")?
	mercado_pago_payment_id: string?
	preference_id: string?

	// Cobro automático (solo lo escriben las Cloud Functions)
	subscription_id: string? // documento en subscriptions
	subscription_status: "pending" | "authorized" | "paused" | "cancelled"?
	subscription_membership_type: "week" | "month"?
	subscription_next_payment_at: timestamp?

	-- direct-transfer only
	reference_id: string?

	-- cash & direct-transfer
	approver_ref: ref?

	creation_date: timestamp
	deletion_date: timestamp?

subscriptions // una por cada autorización de cobro automático
	uid: string
	membershipType: "week" | "month"
	membershipPlanId: number
	amount: number
	currency: "MXN"
	frequencyDays: number
	status: "creating" | "creation_failed" | "pending" | "authorized" | "paused" | "cancelled"
	preapprovalId: string // id de la suscripción en Mercado Pago
	checkoutUrl: string
	nextPaymentAt: timestamp?
	createdAt: timestamp
```

Cada cobro automático aprobado se registra también en `payments` con
`source: "subscription"` y el id `mp_subscription_{authorizedPaymentId}`.
