# 🥭 Mango

App mobile en Flutter para gestionar gastos personales. Proyecto de Taller
de Programación 3 (TP3).

## Quick start

```bash
flutter pub get
flutter run
```

Crear un usuario desde la pantalla de registro para entrar — la auth corre
contra Firebase, no hay usuarios de prueba.


## Stack

- Flutter + Dart
- Riverpod (Notifier moderno)
- go_router con StatefulShellRoute
- fl_chart para gráficos
- Firebase Auth + Firestore

## Estructura

```
lib/
├── core/         # Router + Theme
├── domain/       # Entidades + interfaces de repos
├── data/         # Implementación de repos contra Firebase
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
- ✅ Estadísticas: pie chart mensual 
- ✅ Bottom navbar (Home / Estadísticas / Perfil)
- ✅ Cotización en vivo desde dolarapi.com