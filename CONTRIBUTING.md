# CONTRIBUTING.md

## Convención de commits

Para mantener un historial de cambios claro y uniforme, el proyecto utiliza
la convención de Conventional Commits.

La estructura de los commits será:

<tipo>: <descripción breve>

### Tipos de commit

- feat: nueva funcionalidad.
- fix: corrección de errores.
- docs: cambios en documentación.
- refactor: modificación del código sin agregar funcionalidad.
- test: creación o modificación de pruebas.
- chore: tareas de mantenimiento.
- style: cambios relacionados con formato o estilo.

### Ejemplos

feat: agregar módulo de clientes

fix: corregir validación del formulario de login

docs: actualizar documentación del proyecto

refactor: reorganizar servicio de autenticación


## Versionamiento semántico

El proyecto utiliza versionamiento semántico bajo el formato:

vMAJOR.MINOR.PATCH

### MAJOR

Se incrementa cuando existen cambios importantes que pueden afectar
la compatibilidad de la aplicación.

Ejemplo:

v1.0.0 → v2.0.0

### MINOR

Se incrementa cuando se agrega una nueva funcionalidad manteniendo
la compatibilidad con la versión anterior.

Ejemplo:

v1.0.0 → v1.1.0

### PATCH

Se incrementa cuando se realizan correcciones de errores o cambios
menores.

Ejemplo:

v1.1.0 → v1.1.1


## Version de compilación

La versión publicada debe mantenerse sincronizada con la versión
de compilación de la aplicación.

Ejemplo:

Versión: v1.0.0
Build version: 1.0.0
Version code: 1


## Reglas para contribuciones

1. Crear una rama para cada funcionalidad o corrección.
2. Utilizar Conventional Commits.
3. Mantener los cambios relacionados con una tarea específica.
4. Verificar que el proyecto compile correctamente antes de realizar
   el Pull Request.
5. Crear un Pull Request hacia la rama principal.
6. Revisar los cambios antes de integrarlos a la rama principal.