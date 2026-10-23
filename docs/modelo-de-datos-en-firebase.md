# Modelo de Datos en Firebase

Versión 18.13.1

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
users
	uid: string
	name: string
	last_name: string
	type: "owner" | "member" | "receptionist"
	birth_date: timestamp
	email: string
	phone: string
	photo_url: string?
	legal_data_are_theirs: boolean
	registration_payed: boolean

	membership_plan_id: number?

	guardian_name: string?
	guardian_phone: string?
	guardian_relationship: string?
	curp_url: string?
	curp_validated: boolean

	signature_url: string
	ine_back_url: string
	ine_front_url: string
	ine_back_validated: boolean
	ine_front_validated: boolean

	sample_class_date: timestamp?

	creation_date: timestamp
	deletion_date: timestamp?

membership_plans
	id: string
	amount: double

payments
	uid: string
	type: "cash" | "direct-transfer" | "mercado-pago"

	amount: double
	currency: "MXN" | "USD"
	membership_plan_ref: reference?
	validated: boolean

	checkout_url: string?
	status: ("approved" | "rejected")?
	mercado_pago_payment_id: string?
	preference_id: string?
	approval_date: timestamp?

	payment_data_ref: reference

	creation_date: timestamp

```
