---
    title: Inscripción de un usuario
---
flowchart TB
    Inicio([Inicio])
    PedirEsPreviamenteInscrito[/previously_signed_in/]
    DatosBasicos[/profile_picture, name, last_name/]
    Edad[/birth_date/]
    EsMayorDeEdad{¿Es mayor de edad?}
    PedirDocumentosMayorEdad[/ine_front, ine_back/]
    PedirDocumentosMenorEdad[/guardian_ine_front, guardian_ine_back, curp/]
    PedirDatosTutor[/guardian_name, guardian_phone, .../]
    PedirTipoMembresia[/membership_plan/]
    CalcularPagoTotal[total_payment = 120]
    TamizarTipoMembresia{{membership_plan}}
    CalcularPagoTotalPlanSemanal[total_payment += 280]
    CalcularPagoTotalPlanMensual[total_payment += 600]
    EsPreviamenteInscrito{¿El usuario ya se había inscrito anteriormente al gimnasio?}
    CalcularPagoTotalCero[total_payment = 0]
    CalcularUsuarioRectificadoFalso[rectified_user = false]
    EjecutarGuardarMiembro[[signMemberIn&lpar;&rpar;]]
    PedirMetodoPago[/payment_method/]
    EsPreviamenteInscrito2{¿El usuario ya se había inscrito anteriormente al gimnasio?}
    EjecutarProcesarPago[[processPayment&lpar;&rpar;]]
    Fin([Fin])

    Inicio --> PedirEsPreviamenteInscrito
    PedirEsPreviamenteInscrito --> DatosBasicos
    DatosBasicos --> Edad
    Edad --> EsMayorDeEdad
    EsMayorDeEdad -->|Sí|PedirDocumentosMayorEdad
    EsMayorDeEdad -->|No|PedirDatosTutor
    PedirDatosTutor --> PedirDocumentosMenorEdad
    PedirDocumentosMayorEdad --> PedirTipoMembresia
    PedirDocumentosMenorEdad --> PedirTipoMembresia
    PedirTipoMembresia --> CalcularPagoTotal
    CalcularPagoTotal --> TamizarTipoMembresia
    TamizarTipoMembresia -->|semanal|CalcularPagoTotalPlanSemanal
    TamizarTipoMembresia -->|mensual|CalcularPagoTotalPlanMensual
    CalcularPagoTotalPlanSemanal --> EsPreviamenteInscrito
    CalcularPagoTotalPlanMensual --> EsPreviamenteInscrito
    TamizarTipoMembresia -->|sin plan| EsPreviamenteInscrito
    EsPreviamenteInscrito -->|Sí| CalcularPagoTotalCero
    CalcularPagoTotalCero --> CalcularUsuarioRectificadoFalso
    EsPreviamenteInscrito -->|No| PedirMetodoPago
    PedirMetodoPago --> CalcularUsuarioRectificadoFalso
    CalcularUsuarioRectificadoFalso --> EjecutarGuardarMiembro
    EjecutarGuardarMiembro --> EsPreviamenteInscrito2
    EsPreviamenteInscrito2 -->|No|EjecutarProcesarPago
    EsPreviamenteInscrito2 -->|Sí|Fin
    EjecutarProcesarPago --> Fin
