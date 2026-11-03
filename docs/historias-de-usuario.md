# Historias de Usuario

Versión: 4.15.3

## Clasificación de Cambios

- Cambios mayores
  - Añadir una nueva historia de usuario de tipo A IMPLEMENTAR
  - Cambiar la definición de una entidad
  - Renombrar una entidad

- Cambios menores
  - Añadir una nueva historia de usuario de tipo NO SE IMPLEMENTARÁ
  - Cambios de redacción de una historia de usuario

- Parches
  - Cambios en el formato del documento

## Definiciones

```
Cliente :=
    | Miembro regular
    | Miembro becado
    | Miembro menor de edad
    | Usuario ocasional
    | Usuario prospecto

Miembro pagante :=
    | Miembro regular
    | Miembro menor de edad

Miembro general := 
    | Miembro regular
    | Miembro becado
    | Miembro menor de edad

Usuario :=
    | Administrador
    | Recepcionista
    | Miembro regular
    | Miembro becado
    | Miembro menor de edad
    | Usuario ocasional
    | Usuario prospecto

Usuario sin membresía :=
    | Usuario ocasional
    | Usuario prospecto
```

## Épica CRA-1

### Enunciado de la Épica

Como administrador, 
Quiero digitalizar la gestión de las ventas de productos del gimnasio 
Para llevar un control más minucioso de mis ventas

### Historias de Usuario

```text
Administrador
    CREATE


    READ
        Como administrador,
        Quiero saber cuánto he ganado por las ventas de productos en la tienda del gimnasio
        Para evaluar el desempeño de esta entrada de dinero de Champion's Ring

        Como administrador, 
        Quiero saber qué tan rentable es cada producto de la tienda
        Para tomarlo en consideración al momento de resurtir

        Como administrador,
        Quiero poder recuperar los datos de cualquier venta realizada en la tienda del gimnasio
        Para poder auditar ingresos cuando sea necesario

    UPDATE


    DELETE

Recepcionista
    CREATE
        Como recepcionista,
        Quiero llevar un registro detallado de las ventas que realizo durante el día
        Para poder justificar mi trabajo en caso de una auditoría

    UPDATE
        Como recepcionista, 
        Quiero poder modificar libremente la información del registro de mis ventas en caso de inexactitud
        Para hacer que la información de mi registro coincida con la realidad

        Como recepcionista, 
        Quiero poder modificar libremente la cantidad en inventario de un producto en caso de inexactitud
        Para hacer coincidir el inventario con la realidad

Miembro

```

## Épica CRA-4

### Enunciado de la Épica

```text
Como administrador, 
Quiero digitalizar el proceso de inscripción de nuevos miembros 
Para facilitar su integración al gimnasio
```

### Historias de Usuario

```text
Administrador
    Como administrador, 
    Quiero tener registrada la información del tutor de los miembros menores de edad 
    Para facilitarles el acceso mientras evito problemas legales

    Como administrador,
    Quiero tener un medio con el cual contactar a los usuarios sin membresía
    Para enviarles información sobre la oferta de Champion's Ring y alentarlos a inscribirse en un futuro

Recepcionista
    Como recepcionista, 
    Quiero registrar nuevos miembros en la computadora de la recepción 
    Para captar nuevos clientes fácilmente

    Como recepcionista,
    Quiero visualizar el estatus de la suscripción de los miembros pagantes que llegan al gimnasio
    Para otorgarles el acceso de ser apropiado

    Como recepcionista,
    Quiero visualizar el estatus de la beca de los miembros becados que llegan al gimnasio
    Para otorgarles el acceso de ser apropiado

    Como recepcionista,
    Quiero actualizar los datos de contacto de los miembros del gimnasio
    Para mantener una vía de comunicación con ellos y poderles enviar información relevante del gimnasio

Miembro regular
    Como miembro regular, 
    Quiero inscribirme al gimnasio remotamente
    Para agilizar mi trámite de inscripción y empezar a entrenar lo más pronto posible 

    Como miembro regular,
    Quiero actualizar remotamente los datos de contacto que le proporcioné al gimnasio
    Para mantener una vía de comunicación con Champion's Ring sin tener que acudir al establecimiento físicamente

Miembro becado
    Como miembro becado,
    Quiero que se registre el estatus de mi beca
    Para poder acceder a los servicios del gimnasio gratuitamente

Miembro general
    Como miembro general,
    Quiero visualizar los datos personales que le proporcioné al gimnasio
    Para ejercer mi derecho al Acceso del tratamiento de mis datos personales (letra A de los derechos ARCO)

    Como miembro general,
    Quiero eliminar los datos personales que le proporcioné al gimnasio
    Para ejercer mi derecho a la Cancelación del tratamiento de mis datos personales (letra C de los derechos ARCO)

Usuario ocasional
    Como usuario ocasional,
    Quiero poder visualizar los datos personales que le proporcioné al gimnasio
    Para ejercer mi derecho al Acceso del tratamiento de mis datos personales (letra A de los derechos ARCO)
    ^^^^^^NO-SE-IMPLEMENTARÁ^^^^^^

    Como usuario ocasional,
    Quiero poder detener el envío de publicidad por parte del gimnasio,
    Para evitar saturarme de información que no me es relevante
    ^^^^^^NO-SE-IMPLEMENTARÁ^^^^^^

Usuario prospecto
    Como usuario ocasional,
    Quiero poder detener el envío de publicidad por parte del gimnasio,
    Para evitar saturarme de información que no me es relevante
    ^^^^^^NO-SE-IMPLEMENTARÁ^^^^^^

```

## Épica CRA-5

### Enunciado de la Épica

Como administrador, 
Quiero digitalizar el proceso de pagos de las suscripciones del gimnasio 
Para llevar un control más minucioso y evitar pérdidas

### Historias de Usuario

```
Administrador
    Como administrador,
    Quiero que los clientes del gimnasio tengan la opción de pagar por productos y servicios con una transferencia a mi cuenta de banco
    Para poder recaudar los ingresos de Champion's Ring en un medio más conveniente y seguro que el efectivo

    Como administrador,
    Quiero saber cuánto he ganado por los pagos de las suscripciones del gimnasio
    Para evaluar el desempeño de mi negocio

Recepcionista
    CREATE
        Como recepcionista,
        Quiero poder activar el estado de la suscripción de un miembro cuando se acerque a pagar su membresía en recepción
        Para darle acceso al gimnasio inmediatamente

    READ
        Como recepcionista,
        Quiero saber si la suscripción de un miembro general ya está vencida
        Para poder solicitarle un nuevo pago

        Como recepcionista,
        Quiero saber si un pago con transferencia fue exitoso
        Para notificarle a cliente emisor de no ser así

Miembro pagante
    CREATE
        Como miembro pagante,
        Quiero que mi suscripción al gimnasio se cargue automáticamente a mi cuenta de banco
        Para estar al día con mis pagos y seguir teniendo acceso al establecimiento

Cliente
    CREATE
        Como cliente,
        Quiero poder pagar por productos y servicios del gimnasio usando efectivo
        Para acceder a éstos usando el efectivo que cargo conmigo

Usuario ocasional

Usuario prospecto

```

## Épica CRA-6

### Enunciado de la Épica

Como administrador, 
Quiero digitalizar el formato de no responsabilidad del gimnasio ante accidentes en el ring 
Para mejorar el control de estos formatos y evitar problemas legales a futuro
