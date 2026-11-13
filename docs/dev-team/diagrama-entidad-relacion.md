# Diagrama Entidad Relación del Modelo de Datos en Firebase

Versión 1.0.0

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

```mermaid
erDiagram
    USER ||--o| MEMBER : "is"
    USER ||--o{ PURCHASE : "issues"

    MEMBER ||--o{ RENEWAL : "carries_out"

    RENEWAL }o--|| SUBSCRIPTION : "applies_to"
    RENEWAL ||--|| PAYMENT : "requires"

    PURCHASE ||--|| PAYMENT : "requires"
    PURCHASE }o--o{ PRODUCT : "includes"

    RECEPTIONIST ||--o{ PURCHASE : "registers_1"
    RECEPTIONIST ||--o{ PRODUCT : "registers_2"
    RECEPTIONIST ||--o{ RENEWAL : "registers_3"

    ADMINISTRATOR ||--o{ PRODUCT : "registers_4"

    USER {
    }

    MEMBER {
    }

    RECEPTIONIST {
    }

    ADMINISTRATOR {
    }

    PURCHASE {
    }

    PRODUCT {
    }

    PAYMENT {
    }

    RENEWAL {
    }

    SUBSCRIPTION {
    }
```