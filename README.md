# PlayApp Movil Flutter

Aplicación móvil en **Flutter** desarrollada para **PlayApp** (migración de las funcionalidades principales de la aplicación web en Java).

## Requisitos

- Flutter SDK (`3.47.2` o compatible)
- Dart SDK (`3.13.2` o compatible)
- Android Studio / Xcode / VS Code según la plataforma objetivo

## Cómo ejecutar el proyecto

```bash
flutter pub get
flutter run
```

## Estructura inicial

- `lib/main.dart` — punto de entrada de la aplicación Flutter
- `test/` — pruebas unitarias y de widgets
- `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` — configuración por plataforma

## Flujo de colaboración (Git)

1. Clonar el repositorio e instalar dependencias con `flutter pub get`.
2. Crear una rama por funcionalidad (`git checkout -b feat/nombre-funcionalidad`).
3. Ejecutar `dart analyze` y `flutter test` antes de abrir un Pull Request hacia `main`.
