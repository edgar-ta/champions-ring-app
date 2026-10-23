# Funcionalidades del Módulo Web
Versión: 1.0.0

## Funcionalidades
```
Registrar usuarios prospectos
    Debe haber un apartado para que el recepcionista pueda registrar 
    los datos personales de un usuario prospecto.

    El recepcionista ingresa al apartado y ve una input en la que puede llenar
    nombre y apellidos y correo del usuario prospecto.

    Al dar clic al formulario, el sistema debe realizar el siguiente proceso:
    - Buscar al usuario en el sistema
    - Si el usuario existe en el sistema:
      - Informarle al recepcionista que el usuario ya no puede tomar una clase
        de muestra. Si el usuario tiene registrada una fecha en la que tomó la clase
        de muestra, mostrarle al usuario esa fecha junto con un mensaje descriptivo
    - Si el usuario no existe en el sistema:
      - Registrar al usuario únicamente usando su nombre, apellidos y correo y 
        guardar la fecha actual como la fecha en la cual el usuario tomó la clase de 
        muestra.

Registrar usuarios ocasionales
    Debe haber un apartado para que el recepcionista pueda registrar
    los datos personales de un usuario ocasional.

    Este apartado también debe permitir registrar el pago de la visita
    de dicho usuario.

    - Buscar al usuario en el sistema
    - Si el usuario existe en el sistema:
      - El sistema debe permitirle al recepcionista registrar al usuario.
        Si se desea registrar al usuario, solo se guardarán su nombre,
        apellidos y correo electrónico.
      - Al darle clic al botón, se le debe mostrar al recepcionista
        un formulario para que registre el pago del usuario por alguno
        de los medios aceptados: efectivo, transferencia o con Mercado Pago
      - En cualqiuera de las opciones de los métodos de pago, se debe
        llenar automáticamente el monto a pagar, el cual debe venir
        de la colección de planes de membresía, específicamente, del 
        registro con id "visita"
    - Si el usuario no existe en el sistema:
      - El sistema debe permitirle al recepcionista registrar al usuario
  
Validar documentos de nuevos miembros
    Debe haber un apartado para que el recepcionista pueda marcar la INE (la 
    parte del frente y del revés) y CURP de un miembro como válidos.

    En este apartado debe haber un listado de los usuarios con archivos no
    válidos. Los usuarios se representarán como una tile; el primer elemento
    de la tile es la fotografía de perfil del usuario; posteriormente, le
    acompañan botones para visualizar y validar frente y revés del INE
    y CURP (la CURP solo se muestra en caso de que el usuario sea menor de 
    edad).

    Las tiles de este apartado están ordenadas según la fecha de creación
    del documento asociado al usuario.

    Cuando el recepcionista termina de validar los documentos de un miembro,
    estos desaparecen del apartado.
```
