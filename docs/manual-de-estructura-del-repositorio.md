# Manual de Estructura del Repositorio

Versión 2.0.0

# 1. Objetivo

El proyecto utiliza una estructura organizada por **features (funcionalidades)**. El objetivo es mantener relacionado en un mismo lugar todo el código correspondiente a una funcionalidad de la aplicación y facilitar el trabajo simultáneo de los integrantes del equipo.

La estructura busca ser sencilla y adecuada para el tamaño actual del proyecto, evitando agregar capas o abstracciones innecesarias.

# 2. Estructura general

El código principal de la aplicación (el cual se encuentra dentro de la carpeta `lib/`) sigue la siguiente estructura general:

```text
lib/
├── main.dart
│
├── core/
│   ├── constants/
│   ├── router/
│   └── utils/
│
├── features/
│   ├── authentication/
│   │   ├── enums/
│   │   ├── models/
│   │   ├── repositories/
│   │   ├── screens/
│   │   ├── services/
│   │   └── widgets/
│   ├── members/
│   ├── subscriptions/
│   └── ...
│
└── shared/
    ├── widgets/
    └── theme/
```



# 3. `core/`

La carpeta `core/` contiene lógica e infraestructura **general de la aplicación** que puede ser utilizada por varias features.

No debe contener código exclusivo de una funcionalidad.

### `core/constants/`

Contiene valores constantes compartidos por toda la aplicación, evitando que estos valores se definan repetidamente en diferentes features.

### `core/router/`

Contiene la navegación general de la aplicación.

Aquí se definen las rutas que conectan diferentes pantallas y features.

El router pertenece a `core` porque **coordina diferentes funcionalidades** de la aplicación.

### `core/utils/`

Contiene funciones, clases o herramientas auxiliares de propósito general que facilitan tareas comunes de la aplicación y que pueden ser utilizadas por varias features.

Un archivo pertenece a core/utils/ si proporciona una herramienta reutilizable para realizar una operación, pero no representa una regla de negocio específica de una feature.

# 4. `features/`

Esta es la carpeta principal del proyecto.

Cada entrada de la lista en el archivo `lista-de-funcionalidades.md` debe tener su propia carpeta. La carpeta debe coincidir con el nombre de la entrada que tiene asociada.

Ejemplo:

```text
features/
├── authentication/
├── members/
├── subscriptions/
└── payments/
```

La regla principal es:

> **Si un código pertenece exclusivamente a una funcionalidad, debe vivir dentro de la carpeta de esa funcionalidad.**



# 5. Estructura interna de una feature

Una feature puede organizarse de la siguiente manera:

```text
authentication/
├── enums/
├── models/
├── repositories/
├── screens/
└── widgets/
```

No es obligatorio crear todas las carpetas desde el principio.

**Solo se crean las carpetas que realmente sean necesarias.**



# 6. `<feature>/screens/`

Contiene las pantallas completas de una feature.

Ejemplo:

```text
authentication/
└── screens/
    ├── login_screen.dart
    └── register_screen.dart
```

Una `Screen` representa una vista completa de la aplicación.

Ejemplos:

* Pantalla de inicio de sesión.
* Pantalla de registro.
* Pantalla de perfil.
* Pantalla de administración de membresía.

### Regla

Si el archivo representa una **pantalla completa**, debe ir en `screens/`.

# 7. `<feature>/services/`

Contiene los servicios propios de la feature, encargados de ejecutar o coordinar operaciones que involucran lógica de negocio y que pueden utilizar uno o más repositories, servicios u otras dependencias.

Un archivo pertenece a esta carpeta cuando su responsabilidad principal es realizar una operación o proceso de la feature, en lugar de encargarse directamente de la persistencia o acceso a los datos.

# 8. `<feature>/widgets/`

Contiene componentes de interfaz reutilizables dentro de una feature.

Ejemplo:

```text
authentication/
└── widgets/
    └── register_form.dart
```


La diferencia es:

```text
screens/ → pantallas completas
widgets/ → componentes utilizados dentro de las pantallas
```

No es necesario crear un widget para cada `Text`, `Button` o `Container`.

Se recomienda crear un widget cuando:

* Tiene una responsabilidad clara.
* Tiene suficiente complejidad.
* Se reutiliza.
* Hace que una pantalla sea más fácil de leer.



# 8. `<feature>/models/`

Contiene las clases que representan los datos de la feature.

Por ejemplo:

```text
authentication/
└── models/
    ├── user.dart
    └── register_user_data.dart
```

Ejemplo

```dart
// user.dart

class User {
  final String uid;
  final UserType type;
  // ...
}
```

# 9. `<feature>/enums/`

Contiene enumeraciones relacionadas con la feature.

Por ejemplo:

```text
authentication/
└── enums/
    ├── user_type.dart
    └── user_register_reason.dart
```

Ejemplo:

```dart
// user_type.dart

enum UserType {
  member,
  receptionist,
  owner,
}
```

Si un `enum` solamente tiene sentido dentro de una feature, debe permanecer dentro de esa feature. Si posteriormente se convierte en un concepto utilizado por toda la aplicación, puede evaluarse moverlo a `core/`.



# 10. `<feature>/repositories/`

Los repositories contienen la lógica necesaria para **obtener o modificar datos**.

Esta arquitectura permite mantener separada la interfaz de usuario de la lógica de acceso a datos.

Por ejemplo:

```text
authentication/
└── repositories/
    ├── user_repository.dart
    └── firebase_user_repository.dart
```

Ejemplo:
```dart
user_repository.dart

abstract class UserRepository {
  Future<Result<User, UserRegisterReason>> registerUser(
    RegisterUserData data,
  );
}
```



# 11. `shared/`

La carpeta `shared/` contiene elementos reutilizables por **varias features**, pero que no pertenecen a la lógica global de la aplicación.

Ejemplo:

```text
shared/
└── widgets/
    ├── custom_button.dart
    ├── loading_indicator.dart
    └── ...
```

La diferencia entre `shared/` y `core/` es:

```text
core/
→ infraestructura y elementos fundamentales de la aplicación.

shared/
→ componentes reutilizables entre diferentes features.
```

Por ejemplo:

```text
AppRouter
→ core/router/

Result
→ core/utils/result/

CustomButton
→ shared/widgets/

RegisterForm
→ features/authentication/widgets/
```



# 12. ¿Dónde colocar un archivo nuevo?

Utiliza el siguiente diagrama para determinar la ubicación de un nuevo archivo:

```text
¿Es global?
│
├── Sí → ¿Es infraestructura/lógica fundamental?
│          ├── Sí → core/
│          └── No → shared/
│
└── No → features/<feature>/
              │
              ├── Pantalla       → screens/
              ├── UI reutilizable → widgets/
              ├── Datos          → models/
              ├── Enumeración    → enums/
              └── Acceso a datos → repositories/
```




# 13. Procedimiento para crear nuevas features

Cuando se agregue una nueva funcionalidad, primero se debe crear su carpeta dentro de `features/`.

Por ejemplo:

```text
features/
├── authentication/
├── members/
├── subscriptions/
└── payments/
```

Después se crean únicamente las carpetas necesarias.

Por ejemplo, si `subscriptions` solamente necesita una pantalla y un modelo:

```text
subscriptions/
├── models/
│   └── subscription.dart
│
└── screens/
    └── subscriptions_screen.dart
```

No se deben crear carpetas vacías solamente para mantener una estructura idéntica.



# 14. Reglamento general del repositorio

Para mantener el proyecto ordenado:

1. **Una feature debe contener su propia lógica.**
2. **No colocar código específico de una feature en `core/`.**
3. **No colocar componentes específicos de una feature en `shared/`.**
4. **Evitar archivos que mezclen responsabilidades.**
5. **Crear carpetas solamente cuando sean necesarias.**
6. **Mantener los modelos independientes de la interfaz gráfica.**
7. **Las pantallas no deben comunicarse directamente con Firebase.**
8. **El acceso a Firebase debe realizarse mediante repositories.**
9. **Antes de crear una abstracción nueva, comprobar si realmente aporta reutilización o separación de responsabilidades.**
10. **Si una pieza de código puede pertenecer claramente a una sola feature, debe permanecer dentro de ella.**


