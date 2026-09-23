# Manual de estructura de features

## Champion's Ring App

### 1. Objetivo

El proyecto utiliza una estructura organizada por **features (funcionalidades)**. El objetivo es mantener relacionado en un mismo lugar todo el código correspondiente a una funcionalidad de la aplicación y facilitar el trabajo simultáneo de los integrantes del equipo.

La estructura busca ser sencilla y adecuada para el tamaño actual del proyecto, evitando agregar capas o abstracciones innecesarias.

---

## 2. Estructura general

El código principal de la aplicación se encuentra dentro de `lib/`:

```text
lib/
├── main.dart
│
├── core/
│   ├── router/
│   │   ├── app_router.dart
│   │   └── route_names.dart
│   │
│   ├── constants/
│   ├── theme/
│   └── result/
│       └── result.dart
│
├── features/
│   ├── authentication/
│   ├── members/
│   ├── subscriptions/
│   └── ...
│
└── shared/
    └── widgets/
```

Cada carpeta tiene una responsabilidad específica.

---

# 3. `core/`

La carpeta `core/` contiene elementos **generales de la aplicación** que pueden ser utilizados por varias features.

No debe contener código exclusivo de una funcionalidad.

Por ejemplo:

```text
core/
├── router/
├── constants/
├── theme/
└── result/
```

### `core/router/`

Contiene la navegación general de la aplicación.

```text
core/router/
├── app_router.dart
└── route_names.dart
```

Aquí se definen las rutas que conectan diferentes pantallas y features.

Por ejemplo:

```text
Login
  ↓
Registro
  ↓
Inicio
  ↓
Perfil
```

El router pertenece a `core` porque **coordina diferentes funcionalidades** de la aplicación.

---

# 4. `features/`

Esta es la carpeta principal del proyecto.

Cada funcionalidad importante de la aplicación debe tener su propia carpeta.

Ejemplo:

```text
features/
├── authentication/
├── members/
├── subscriptions/
└── payments/
```

La regla principal es:

> **Si un código pertenece exclusivamente a una funcionalidad, debe vivir dentro de esa feature.**

---

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

---

# 6. `screens/`

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

---

# 7. `widgets/`

Contiene componentes de interfaz reutilizables dentro de una feature.

Ejemplo:

```text
authentication/
└── widgets/
    └── register_form.dart
```

Por ejemplo, `RegisterScreen` puede utilizar:

```text
RegisterScreen
      │
      └── RegisterForm
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

---

# 8. `models/`

Contiene las clases que representan los datos de la feature.

Por ejemplo:

```text
authentication/
└── models/
    ├── user.dart
    └── register_user_data.dart
```

### `User`

Representa un usuario existente dentro del sistema.

```dart
class User {
  final String uid;
  final UserType type;
  // ...
}
```

# 9. `enums/`

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
enum UserType {
  member,
  receptionist,
  owner,
}
```

Y:

```dart
enum UserRegisterReason {
  emailAlreadyInUse,
  invalidEmail,
  weakPassword,
  operationNotAllowed,
  authenticationError,
  firestoreError,
  unexpectedError,
}
```

### Regla

Si un `enum` solamente tiene sentido dentro de una feature, debe permanecer dentro de esa feature.

Si posteriormente se convierte en un concepto utilizado por toda la aplicación, puede evaluarse moverlo a `core/`.

---

# 10. `repositories/`

Los repositories contienen la lógica necesaria para **obtener o modificar datos**.

Ejemplo:

```text
authentication/
└── repositories/
    ├── user_repository.dart
    └── firebase_user_repository.dart
```

### `UserRepository`

Define qué operaciones puede realizar la aplicación:

```dart
abstract class UserRepository {
  Future<Result<User, UserRegisterReason>> registerUser(
    RegisterUserData data,
  );
}
```

### `FirebaseUserRepository`

Contiene la implementación utilizando Firebase:

```text
FirebaseUserRepository
        │
        ├── Firebase Authentication
        │
        └── Cloud Firestore
```

La pantalla no debería encargarse directamente de crear usuarios en Firebase.

El flujo será:

```text
RegisterScreen
      ↓
RegisterUserData
      ↓
UserRepository
      ↓
FirebaseUserRepository
      ↓
Firebase Authentication
      +
Cloud Firestore
```

Esto permite mantener separada la interfaz de usuario de la lógica de acceso a datos.

---

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
→ core/result/

CustomButton
→ shared/widgets/

RegisterForm
→ features/authentication/widgets/
```

---

# 12. ¿Dónde colocar un archivo nuevo?

Antes de crear un archivo, responder estas preguntas:

### ¿Pertenece a una feature específica?

**Sí:**

```text
features/<feature>/
```

**No:**

Evaluar si pertenece a `core/` o `shared/`.

---

### ¿Es una pantalla?

```text
screens/
```

### ¿Es un componente de interfaz?

```text
widgets/
```

### ¿Representa datos?

```text
models/
```

### ¿Es una enumeración?

```text
enums/
```

### ¿Obtiene o modifica datos?

```text
repositories/
```

### ¿Es utilizado por toda la aplicación?

Evaluar:

```text
core/
```

o:

```text
shared/
```

---

# 15. Regla para crear nuevas features

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

---

# 16. Regla general del repositorio

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

---

# 17. Diagrama de selección de carpeta

Cuando exista duda sobre dónde colocar algo, utilizar esta referencia:

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

El objetivo no es tener la estructura más sofisticada posible, sino que **cualquier integrante pueda abrir el repositorio y saber dónde debe colocar su código sin introducir dependencias innecesarias**.
