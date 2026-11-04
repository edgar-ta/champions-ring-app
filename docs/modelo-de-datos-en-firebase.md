# Modelo de Datos en Firebase

Versión 1.0.0

```txt
users
	uid: string
	name: string
	last_name: string
	type: "owner" | "member" | "receptionist"
	birth_date: string
	email: string
	phone: string
	legal_data_are_theirs: boolean
	liability_waiver_url: string // PDF de la carta responsiva firmada
	ine_url: string
	registration_payed: boolean
	creation_date: timestamp
	deletion_date: timestamp?
	// Cobro automático (solo lo escriben las Cloud Functions)
	subscription_id: string? // documento en subscriptions
	subscription_status: "pending" | "authorized" | "paused" | "cancelled"?
	subscription_membership_type: "week" | "month"?
	subscription_next_payment_at: timestamp?

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
