# Modelo de Datos en Firebase

Versión 22.1.0

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
    - Por ejemplo, al añadir un valor a una enumeración de un atributo nulable

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

    sampleClassDate?: timestamp

    creationDate: timestamp
    deletionDate?: timestamp

members
    uid: string
    birthDate: timestamp
    phone: string
    photoUrl?: string
    legalDataAreTheirs: boolean
    inscriptionPaid: boolean

    membershipPlanRef?: reference
    latestRenewalRef?: reference

    guardianName?: string
    guardianPhone?: string
    guardianRelationship?: string
    curpUrl?: string
    curpValidated?: boolean

    ineBackUrl: string
    ineBackValidated: boolean
    ineFrontUrl: string
    ineFrontValidated: boolean

    waiverAgreementUrl?: string
    waiverAgreementValidated?: boolean

    creationDate: timestamp
    deletionDate?: timestamp

    renewals/
        uid: string
        startDate: timestamp
        endDate: timestamp
        membershipPlanRef: reference
        paymentRef: reference
        amount: double

        creationDate: timestamp
        deletionDate?: timestamp

receptionists
    uid: string
    name: string
    lastName: string
    email: string

    creationDate: timestamp
    deletionDate?: timestamp

administrators
    uid: string
    name: string
    lastName: string
    email: string

    creationDate: timestamp
    deletionDate?: timestamp

membership_plans
    uid: string
    cost: double
    benefits: string
    duration: "1d" | "1w" | "1m"
    name: string
    isRenewable: boolean

    creationDate: timestamp
    deletionDate?: timestamp

payments
    uid: string
    type: "cash" | "direct-transfer" | "mercado-pago"

    amount: double
    currency: "MXN" | "USD"
    approvalDate?: timestamp
    payerRef?: ref

    -- mercado-pago only
    checkoutUrl?: string
    status?: "approved" | "rejected" | "processing" | "canceled" | "refunded"
    preferenceId?: string
    rejectionDetail?: "high_risk" | "rejected_by_issuer" | "insufficient_amount" | "invalid_card_token" | "processing_error" | string

    -- direct-transfer only
    referenceId?: string
    issuingEntity?: ("bbva" | "santander" | "banco-azteca" | "elektra" | "other")
    issuingEntityName?: string

    -- cash & direct-transfer
    approverRef?: ref

    creationDate: timestamp
    deletionDate?: timestamp

purchases
    uid: string

    items/
        uid: string
        numberOfProducts: number
        productRef: reference
        individualPrice: number
```

## Mantenimiento de referencias internas

Cada vez que se actualice este documento, se deben buscar en el repositorio los archivos
que contengan un doc tag con el formato
`@docs[ docs/dev-team/modelo-de-datos-en-firebase.md v{version} ]` y actualizar
las referencias que correspondan a la nueva versión.
