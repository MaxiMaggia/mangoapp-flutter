# 🥭 Mango

App mobile en Flutter para gestionar gastos personales. Proyecto de Taller
de Programación 3 (TP3).

## Quick start

```bash
flutter pub get
flutter run
```

Login de prueba (Fake repo en memoria):

- **Email**: `demo@mango.com`
- **Password**: `123456`

## Documentación

- [`CLAUDE.md`](./CLAUDE.md) — Lineamientos completos de arquitectura, patrones
  y reglas del proyecto. **Leer antes de modificar código.**
- [`PROGRESS.md`](./PROGRESS.md) — Qué está hecho y qué falta.

## Stack

- Flutter + Dart
- Riverpod (Notifier moderno)
- go_router con StatefulShellRoute
- fl_chart para gráficos
- Firebase Auth + Firestore *(pendiente de integrar — hoy son Fakes en memoria)*

## Estructura

```
lib/
├── core/         # Router + Theme
├── domain/       # Entidades + interfaces de repos
├── data/         # Implementación de repos (hoy Fake, mañana Firebase)
└── presentation/
    ├── screens/
    ├── widgets/
    ├── viewmodels/
    │   ├── notifiers/
    │   └── states/
    └── utils/
```

## Features

- ✅ Login + Register
- ✅ CRUD de gastos
- ✅ CRUD de categorías
- ✅ Soporte ARS / USD con conversión
- ✅ Estadísticas: pie chart mensual + barras trimestrales
- ✅ Bottom navbar (Home / Estadísticas / Perfil)
- ⏳ Integración Firebase real
- ⏳ Adjuntar comprobantes (Storage)
- ⏳ Cotización en vivo desde dolarapi.com
