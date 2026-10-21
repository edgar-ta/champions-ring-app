Versión: 1.0.0

Funcionalidades del Módulo Web
    Registrar usuarios prospectos
        Debe haber un apartado para que el recepcionista pueda registrar 
        los datos personales de un usuario que solo viene a tomar una clase
        de muestra

        El usuario ingresa al apartado y ve una input en la que puede llenar
        el nombre y correo de la persona que va a tomar la clase de muestra.
        Al dar clic al formulario, el sistema debe realizar el siguiente proceso:
        - Buscar al usuario en el sistema
        - Si el usuario existe en el sistema:
          - Informarle al recepcionista que el usuario ya no puede tomar una clase
            de muestra. Si el usuario tiene registrada una fecha en la que tomó la clase
            de muestra, mostrarle al usuario esa fecha junto con un mensaje descriptivo
        - Si el usuario no existe en el sistema:
          - Registrar al usuario con el tipo "usuario-ocasional" y guardar la fecha
            actual como la fecha en la cual el usuario tomó la clase de muestra

    Registrar usuarios ocasionales
        Debe haber un apartado para que el recepcionista pueda registrar
        un nuevo usuario asociado a un usuario del gimnasio que únicamente
        paga visita pero no está suscrito.

        Este apartado también debe permitir registrar el pago de la visita
        de dicho usuario.
