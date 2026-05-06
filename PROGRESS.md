# PROGRESS.md — Estado del proyecto Mango

Última actualización: primera entrega de vistas.

---

## ✅ Hecho

### Configuración y arquitectura
- [x] Proyecto Flutter creado con estructura **MVVM + Clean** (`core`,
  `domain`, `data`, `presentation` con sus subcarpetas) siguiendo el modelo
  de `riverpod_mvvm_crud` del profe.
- [x] `pubspec.yaml` con todas las dependencias necesarias.
  Las de Firebase quedaron **comentadas** para activarse al integrar.
- [x] `main.dart` con `ProviderScope` + `MaterialApp.router`.
- [x] Tema visual de Mango (`AppTheme.light`) con paleta naranja en
  `core/app_theme.dart`.
- [x] Routing completo con **go_router** y `StatefulShellRoute.indexedStack`
  para los 3 tabs (Home / Estadísticas / Perfil).
- [x] Redirect automático a `/login` o `/home` según haya sesión activa,
  reactivo a cambios del `AuthNotifier` vía `refreshListenable`.

### Domain (capa de entidades + interfaces)
- [x] `Expense` con `Currency` (ARS/USD) + `DolarType` + validators.
- [x] `Category` con `iconKey`, `colorValue` y validators.
- [x] `AppUser`.
- [x] Interfaces `ExpensesRepository`, `CategoriesRepository`,
  `AuthRepository` (con paginación cursor-based ya en la firma).

### Data (capa de implementación)
- [x] **Repositorios fakes en memoria** que cumplen las interfaces:
  `FakeAuthRepository`, `FakeCategoriesRepository`,
  `FakeExpensesRepository`.
- [x] Datos seed: usuario demo (`demo@mango.com / 123456`),
  6 categorías, 12 gastos distribuidos en los últimos 6 meses para que las
  estadísticas tengan algo que mostrar.
- [x] `data/providers.dart` con los `Provider<XxxRepository>` —
  **único punto a tocar** cuando migremos a Firebase.

### Presentation
- [x] `BaseScreenState` sealed class (loading / idle / error)
  idéntico al del profe.
- [x] `Fmt` formatter con money/usd/dates en `es_AR`.
- [x] Catálogo cerrado de **íconos predefinidos** (`CategoryIcons`) y paleta
  de colores (`CategoryColors`) para no necesitar Storage en esta primera
  entrega.

### ViewModels (Notifiers + States)
- [x] `AuthNotifier` (signIn, signUp, signOut).
- [x] `ExpensesListNotifier` con **paginación cursor-based** (pageSize = 10),
  filtro por categoría y búsqueda en memoria.
- [x] `ExpenseFormNotifier` (load, save, validación, conversión USD→ARS
  provisional con tabla local).
- [x] `ExpenseDetailsNotifier` (Family por id).
- [x] `CategoriesListNotifier`, `CategoryFormNotifier`.
- [x] `StatisticsNotifier` con cálculo de pie chart mensual y bar chart
  trimestral.

### Widgets reutilizables
- [x] `MangoLogo` (logo de la marca con gradiente).
- [x] `ExpenseItem` (tarjeta de gasto con `flutter_slidable` y acciones
  editar/eliminar).
- [x] `CategoryItem` y `CategoryChipBadge`.

### Pantallas (todas funcionales sobre Fakes)
- [x] **LoginScreen** — pre-cargado con `demo@mango.com / 123456` para
  probar rápido.
- [x] **RegisterScreen**.
- [x] **MainShell** con `BottomNavigationBar` de 3 tabs.
- [x] **HomeScreen** — lista paginada, búsqueda, filtros por categoría,
  total mostrado, pull-to-refresh, FAB "Nuevo gasto", scroll listener
  para `loadMore`.
- [x] **StatisticsScreen** — header con total mensual + selector de mes,
  pie chart con leyenda y porcentajes, bar chart trimestral con gradiente.
- [x] **ProfileScreen** — header con avatar, "Administrar categorías",
  futuras opciones deshabilitadas (cotización dólar, notificaciones),
  logout con confirmación.
- [x] **ExpenseFormScreen** — alta/edición con descripción, categoría
  (chips horizontales), fecha, toggle ARS/USD, monto, dropdown de tipo de
  cotización si es USD.
- [x] **ExpenseDetailsScreen** — vista de detalle con tarjeta de monto,
  metadata, botones editar/eliminar.
- [x] **CategoryListScreen** con FAB y acciones swipe.
- [x] **CategoryFormScreen** con selector de ícono (grid) y selector de
  color (paleta).

---

## 🚧 Falta (segunda iteración)

### Integración con Firebase
- [ ] Configurar Firebase con `flutterfire configure` (genera
  `firebase_options.dart`).
- [ ] Habilitar Authentication (email/password) en consola Firebase.
- [ ] Descomentar dependencias `firebase_core`, `firebase_auth`,
  `cloud_firestore` en `pubspec.yaml`.
- [ ] Descomentar inicialización en `main.dart`.
- [ ] Implementar:
  - [ ] `FirebaseAuthRepositoryImpl` (probable mapping de `User` → `AppUser`).
  - [ ] `FirestoreExpensesRepositoryImpl` con `withConverter`,
    `fromFirestore`, `toFirestore`. Ver `movie_app_firebase_clean` del profe
    como referencia.
  - [ ] `FirestoreCategoriesRepositoryImpl`.
- [ ] Cambiar lado derecho de los providers en `data/providers.dart` para
  apuntar a las implementaciones reales.
- [ ] **Crear los índices compuestos en Firestore** (mandatorio según el
  profe):
  - [ ] `expenses`: `userId ASC + createdAt DESC` (para paginación de home).
  - [ ] `expenses`: `userId ASC + date ASC` (para estadísticas por rango).
  - [ ] `categories`: `userId ASC + title ASC` (orden alfabético).
- [ ] Reglas de seguridad de Firestore (`firestore.rules`).

### Conversión de moneda real
- [ ] Reemplazar la tabla local en `ExpenseFormNotifier.convertUsdToArs`
  por una llamada real a `https://dolarapi.com/v1/dolares/{casa}` con
  `package:http`. El método pasa a ser `Future<double>`.
- [ ] Habilitar la opción "Cotización del dólar" en el ProfileScreen para
  que el usuario elija el tipo por defecto.

### Comprobantes / archivos adjuntos
- [ ] Agregar Firebase Storage al `pubspec.yaml`.
- [ ] Permitir adjuntar imagen/PDF al gasto desde el form (ya hay un campo
  `attachmentUrl` en `Expense`, falta la UI y la lógica de upload).
- [ ] Mostrar el archivo en `ExpenseDetailsScreen`.

### Imágenes en categorías (opcional, baja prioridad)
- [ ] Hoy las categorías usan íconos predefinidos. Si quisiéramos imágenes
  custom, agregar Storage para subir y guardar la URL en `Category`.

### Tests
- [ ] Tests unitarios de los notifiers usando `mocktail` (la dep ya está
  en `pubspec.yaml` como `dev_dependency`).
- [ ] Tests de validators en las entidades.
- [ ] Tests de la conversión USD→ARS.

### Pulido de UI / UX
- [ ] Animaciones de transición entre pantallas.
- [ ] Empty states con ilustraciones reales.
- [ ] Soporte de modo oscuro.
- [ ] Localización formal con `flutter_localizations` (hoy estamos hardcodeados
  en `es_AR`).

### Misc
- [ ] Splash screen con logo Mango.
- [ ] Iconos del launcher (Android `ic_launcher` + iOS).
- [ ] Asset de ícono de la app reemplazando el de Flutter por defecto.
- [ ] Pantalla de "Recuperar contraseña".
- [ ] Validación de email más estricta (regex).

---

## 📌 Notas para retomar

- Para probar la app: `flutter pub get` → `flutter run`. El login viene
  pre-cargado con el usuario demo.
- Si rompiste algo, leé **CLAUDE.md** primero. Todo el patrón está descrito ahí.
- El profe insiste en: **paginar listas**, **índices Firestore**,
  **lógica en el front**, **nada de back custom**. Cualquier feature nueva
  tiene que respetar estos cuatro mandamientos.
