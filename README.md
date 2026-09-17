# Champion's Ring

[![Flutter CI](https://github.com/edgar-ta/champions-ring-app/actions/workflows/flutter-build.yml/badge.svg?branch=main)](https://github.com/edgar-ta/champions-ring-app/actions/workflows/flutter-build.yml)
[![Pull requests](https://img.shields.io/github/issues-pr/edgar-ta/champions-ring-app)](https://github.com/edgar-ta/champions-ring-app/pulls)

Champion's Ring es una aplicacion para un gimnasio local que incluye una
experiencia movil y un modulo web. El proyecto esta construido con Flutter y
permite centralizar las funcionalidades digitales del gimnasio en una misma
base de codigo.

## Requisitos

- Flutter en el canal `stable`.
- Dart SDK compatible con la version indicada en `app/pubspec.yaml`.
- Un dispositivo movil o emulador para ejecutar la aplicacion movil.
- Google Chrome para ejecutar el modulo web.

Comprueba la instalacion con:

```bash
flutter doctor
```

## Construir y ejecutar

Todos los comandos de Flutter deben ejecutarse desde la carpeta `app`:

```bash
cd app
flutter pub get
```

Para ejecutar la aplicacion en un dispositivo movil o emulador:

```bash
flutter run
```

Para ejecutar el modulo web en Chrome:

```bash
flutter run -d chrome
```

Para construir un APK de Android en modo debug:

```bash
flutter build apk --debug
```

Para construir la version web:

```bash
flutter build web
```

## Verificaciones del CI

Cada pull request dirigido a `main` ejecuta automaticamente:

- Instalacion de dependencias con `flutter pub get`.
- Analisis estatico con `flutter analyze`.
- Pruebas con `flutter test`.
- Construccion de un APK Android con `flutter build apk --debug`.

El workflow se encuentra en
`.github/workflows/flutter-build.yml`.

## Enlaces del proyecto

- [Board de Jira](https://snackup.atlassian.net/jira/software/projects/CRA/boards/68?filter=&groupBy=none&atlOrigin=eyJpIjoiMjNkOGMxOTY2Yjk4NGMxNTg0ODFkYjQ3MzllZGVkMjAiLCJwIjoiaiJ9)
- [Plan de DevOps](https://docs.google.com/document/d/1PH2tMsaNsHezSp0vCosoqWtB99lgMsKbugBkHyg_Iy8/edit?usp=drive_link)
- [Pull requests](https://github.com/edgar-ta/champions-ring-app/pulls)
- [Issues](https://github.com/edgar-ta/champions-ring-app/issues)
