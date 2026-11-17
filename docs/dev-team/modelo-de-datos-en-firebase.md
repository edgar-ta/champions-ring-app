# Modelo de Datos en Firebase

Versión 22.0.0

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
	lastName: string
	email: string

	sampleClassDate: timestamp?

	creationDate: timestamp
	deletionDate: timestamp?

members
	uid: string
	birthDate: timestamp
	phone: string
	photoUrl: string?
	legalDataAreTheirs: boolean
	inscriptionPaid: boolean

	membershipPlanRef: reference?
	latestRenewalRef: reference?

	guardianName: string?
	guardianPhone: string?
	guardianRelationship: string?
	curpUrl: string?
	curpValidated: boolean?

	ineBackUrl: string
	ineBackValidated: boolean
	ineFrontUrl: string
	ineFrontValidated: boolean

	waiverAgreementUrl: string?
	waiverAgreementValidated: boolean?

	creationDate: timestamp
	deletionDate: timestamp?

	renewals/
		uid: string
		startDate: timestamp
		endDate: timestamp
		membershipPlanRef: reference
		paymentRef: reference
		amount: double

		creationDate: timestamp
		deletionDate: timestamp?

receptionists
	uid: string
	name: string
	lastName: string
	email: string

	creationDate: timestamp
	deletionDate: timestamp?

administrators
	uid: string
	name: string
	lastName: string
	email: string

	creationDate: timestamp
	deletionDate: timestamp?

membership_plans
	uid: string
	cost: double
	benefits: string
	duration: "1d" | "1w" | "1m"

	creationDate: timestamp
	deletionDate: timestamp?

payments
	uid: string
	type: "cash" | "direct-transfer" | "mercado-pago"

	amount: double
	currency: "MXN" | "USD"
	approvalDate: timestamp?
	payerRef: ref?

	-- mercado-pago only
	checkoutUrl: string?
	status: ("approved" | "rejected")?
	preferenceId: string?

	// Cobro automático (solo lo escriben las Cloud Functions)
	subscription_id: string? // documento en subscriptions
	subscription_status: "pending" | "authorized" | "paused" | "cancelled"?
	subscription_membership_type: "week" | "month"?
	subscription_next_payment_at: timestamp?

	-- direct-transfer only
	referenceId: string?
	issuingEntity: ("bbva" | "santander" | "banco-azteca" | "elektra" | "other")?
	issuingEntityName: string?

	-- cash & direct-transfer
	approverRef: ref?

	creationDate: timestamp
	deletionDate: timestamp?

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

purchases
	uid: string

	items/
		uid: string
		numberOfProducts: number
		productRef: reference
		individualPrice: number
```

Cada cobro automático aprobado se registra también en `payments` con
`source: "subscription"` y el id `mp_subscription_{authorizedPaymentId}`.
