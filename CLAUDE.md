# CLAUDE.md — Lineamientos del proyecto Mango

> Contexto: este archivo es la fuente de verdad para cualquier agente (Claude
> Code, otra IA, o yo retomando el proyecto en frío) que tenga que tocar
> código en este repo. Antes de escribir una línea, leelo entero. La materia
> es **Taller de Programación 3** y todo lo que está acá replica el estilo
> del profesor (ver `curso_flutter-main` original con sus ejemplos
> `riverpod_mvvm_crud`, `riverpod_mvvm_basic`, `movie_app_firebase_clean`).

---

## 1. Qué es Mango

App mobile en **Flutter** para gestionar gastos personales con:

- Login / registro de usuario.
- CRUD de **gastos** (Expense): nombre, categoría, monto en ARS o USD, fecha.
- CRUD de **categorías** (Category) con ícono y color custom.
- Conversión USD → ARS (lógica en el front, sin backend).
- **Estadísticas**: torta por categoría del mes y barras por trimestre del
  último año.
- Bottom navbar de 3 tabs: **Home / Estadísticas / Perfil**.

Stack obligatorio (lo pidió el profe):

- **Flutter + Dart**
- **Riverpod** (`Notifier` y `AutoDisposeNotifier` modernos, NO `StateNotifier`
  legacy)
- **go_router** (con `StatefulShellRoute.indexedStack` para el navbar)
- **Firebase Auth + Firestore** (sin back propio: "todo de Google")
- **fl_chart** para gráficos
- **flutter_slidable** para acciones swipe en listas
- `equatable`, `intl`, `collection`

> **Reglas duras del profe** (ver `tp3.txt`):
>
> 1. Paginar las listas con limit. *"El que no pagina reprueba"*. Ya está
>    implementado en `ExpensesListNotifier.loadMore`.
> 2. Crear los **índices de Firestore** que las queries necesiten (los
>    compuestos no son automáticos).
> 3. Lógica de negocio en el **front**, no en el back. Los `Notifier` son los
>    encargados.
> 4. **Nunca** llamar a la BD desde la vista. Las vistas leen `state` y disparan
>    métodos del notifier, nada más.
> 5. Sin backend custom. Firebase para todo (Auth, Firestore, Storage en el
>    futuro).

---

## 2. Arquitectura: MVVM + Clean

```
lib/
├── main.dart                       # Entry point + ProviderScope + MaterialApp.router
├── core/
│   ├── app_router.dart             # GoRouter con redirect de auth + 3 branches del shell
│   └── app_theme.dart              # ThemeData con la paleta naranja Mango
│
├── domain/                         # ENTIDADES + INTERFACES de repos. Zero deps externas.
│   ├── expense.dart                # Expense + Currency + DolarType + ExpenseValidator
│   ├── category.dart               # Category + CategoryValidator
│   ├── app_user.dart               # AppUser (no se llama "User" para no chocar con Firebase)
│   ├── expenses_repository.dart    # abstract interface class
│   ├── categories_repository.dart
│   └── auth_repository.dart
│
├── data/                           # IMPLEMENTACIÓN de repos contra Firebase.
│   ├── firebase_auth_repository.dart
│   ├── firestore_categories_repository.dart
│   ├── firestore_expenses_repository.dart
│   ├── firestore_users_repository.dart
│   └── providers.dart              # Provider<AuthRepository>, etc.
│
└── presentation/
    ├── screens/                    # Widgets de pantalla (Scaffold + body)
    ├── widgets/                    # Componentes reutilizables (ExpenseItem, MangoLogo...)
    ├── utils/
    │   ├── base_screen_state.dart  # sealed class loading/idle/error (idéntico al profe)
    │   ├── formatter.dart          # Fmt: money/usd/dates en es_AR
    │   └── category_icons.dart     # Catálogo cerrado de íconos para categorías
    └── viewmodels/
        ├── providers.dart          # Expone TODOS los xxxViewModelProvider
        ├── states/                 # Una clase Equatable por pantalla
        │   └── *_state.dart
        └── notifiers/              # La lógica vive acá
            └── *_notifier.dart
```

**Por qué clean separa `domain` y `data`:** porque la implementación de los
repos (hoy contra Firebase) es intercambiable sin tocar viewmodels ni vistas.
Solo cambia el lado derecho de los providers en `data/providers.dart`.

---

## 3. Patrón de Notifier (mirar `riverpod_mvvm_crud` del profe)

Cada pantalla con estado tiene esta tríada:

1. **Un `XxxState`** en `viewmodels/states/` — Equatable, inmutable, con
   `copyWith`.
2. **Un `XxxNotifier`** en `viewmodels/notifiers/` — extiende `Notifier`,
   `AutoDisposeNotifier` o `AutoDisposeFamilyNotifier`.
3. **Un `xxxViewModelProvider`** en `viewmodels/providers.dart` que conecta
   los dos.

### 3.1 Cuándo usar cada uno

| Tipo                          | Cuándo                                                                                          |
| ----------------------------- | ----------------------------------------------------------------------------------------------- |
| `Notifier`                    | Estados de larga vida que sobreviven entre pantallas. Ej: `ExpensesListNotifier`, `AuthNotifier` |
| `AutoDisposeNotifier`         | Forms y pantallas one-shot. Se limpian al salir. Ej: `ExpenseFormNotifier`, `CategoryFormNotifier` |
| `AutoDisposeFamilyNotifier<S, A>` | Cuando el estado depende de un parámetro (ej: id). Ej: `ExpenseDetailsNotifier(expenseId)`   |

### 3.2 Esqueleto de un Notifier

```dart
class XxxNotifier extends Notifier<XxxState> {
  late final XxxRepository _repo = ref.read(xxxRepositoryProvider);

  @override
  XxxState build() => const XxxState();

  Future<void> fetch() async {
    state = state.copyWith(screenState: const BaseScreenState.loading());
    try {
      final result = await _repo.doSomething();
      state = state.copyWith(
        screenState: const BaseScreenState.idle(),
        data: result,
      );
    } catch (error) {
      state = state.copyWith(
        screenState: BaseScreenState.error(error.toString()),
      );
    }
  }
}
```

### 3.3 BaseScreenState

Sealed class con `loading | idle | error`. Vive en `presentation/utils/base_screen_state.dart`.
**Todos** los States tienen un campo `screenState` para que la vista haga:

```dart
state.screenState.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  idle:    () => _MyContent(...),
  error:   (msg) => Text('Error: $msg'),
)
```

---

## 4. Patrón de Vista (Screen)

```dart
class XxxScreen extends ConsumerStatefulWidget {
  static const name = 'XxxScreen';
  const XxxScreen({super.key});
  @override
  ConsumerState<XxxScreen> createState() => _XxxScreenState();
}

class _XxxScreenState extends ConsumerState<XxxScreen> {
  @override
  void initState() {
    super.initState();
    // Disparar fetch DESPUÉS del primer frame, nunca dentro del build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(xxxViewModelProvider.notifier).fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(xxxViewModelProvider);

    // Reaccionar a "eventos" que vienen como flags en el state.
    ref.listen(xxxViewModelProvider, (_, next) {
      if (next.wasSaved) Navigator.of(context).pop(true);
      if (next.screenState.isError) {
        ScaffoldMessenger.of(context).showSnackBar(...);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('...')),
      body: state.screenState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        idle:    () => _Content(state: state),
        error:   (msg) => _ErrorView(msg: msg),
      ),
    );
  }
}
```

### Reglas duras de las vistas

1. **NUNCA** una vista hace `repository.xxx()` directo. Llama al notifier.
2. **NUNCA** `async` directamente en `build`. Si necesitás iniciar fetch, va
   en `initState` con `addPostFrameCallback`, no en `build`.
3. La navegación tras una acción se decide en la vista vía `ref.listen`
   mirando flags como `wasSaved`, `wasDeleted` del state.

---

## 5. Naming y convenciones

- **Archivos**: snake_case (`expenses_list_notifier.dart`).
- **Clases**: PascalCase (`ExpensesListNotifier`).
- **Providers**: camelCase con sufijo: `xxxRepositoryProvider`,
  `xxxViewModelProvider`.
- **Rutas (`name`)**: cada Screen expone `static const name = 'XxxScreen'`.
  Para forms con dos rutas (new/edit), usar `nameNew` y `nameEdit`.
- **States**: `XxxState extends Equatable`, con `copyWith` que acepte un
  flag `clearXxx` cuando hay que setear un campo a null sin que el
  null-coalescing lo pise.
- **Strings UI**: en español.
- **Strings de código** (entidades, props): en inglés (`name` no `nombre`,
  `amount` no `monto`). Es la convención del profe.

---

## 6. Cómo agregar una feature nueva (receta)

Pongamos que querés agregar **presupuestos mensuales**. Pasos:

1. **Domain**:
   - Crear `domain/budget.dart` con la entidad y validators.
   - Crear `domain/budgets_repository.dart` con la interface.
2. **Data**:
   - Crear `data/firestore_budgets_repository.dart` con `withConverter` y la
     colección correspondiente.
   - Agregar `budgetsRepositoryProvider` en `data/providers.dart`.
3. **ViewModels**:
   - Crear `presentation/viewmodels/states/budgets_list_state.dart`.
   - Crear `presentation/viewmodels/notifiers/budgets_list_notifier.dart`.
   - Exponer `budgetsListViewModelProvider` en
     `presentation/viewmodels/providers.dart`.
4. **Vistas**:
   - Crear `presentation/screens/budgets_screen.dart` siguiendo el patrón
     `ConsumerStatefulWidget` + `initState` + `state.screenState.when(...)`.
   - Si va en el navbar, agregar un branch en `app_router.dart`. Si es push,
     agregar un `GoRoute` con `parentNavigatorKey: _rootNavigatorKey`.
5. **Acceso al user actual**: dentro del notifier,
   `ref.read(authViewModelProvider).user`.

---

## 7. Ruteo (go_router + StatefulShellRoute)

- **`/login`** y **`/register`**: pantallas top-level sin navbar.
- **`/home`**, **`/stats`**, **`/profile`**: viven dentro del
  `StatefulShellRoute.indexedStack`. Cada una es un `branch` con su propio
  navigator → mantienen estado al cambiar de tab.
- **Push routes** (sin navbar): `/expense/new`, `/expense/:id`,
  `/expense/:id/edit`, `/categories`, `/categories/new`,
  `/categories/:id/edit`. Tienen `parentNavigatorKey: _rootNavigatorKey`.

### Redirect de auth

`appRouter` se construye desde un `Provider` (`appRouterProvider`) y usa
`refreshListenable` con un `_AuthRefreshListener` que escucha
`authViewModelProvider`. Cuando el user cambia (login/logout), el router
re-evalúa el redirect y lleva al lugar correcto.

---

## 8. Capa de datos: Firebase

La capa `data/` implementa los repos contra Firebase:

- `FirebaseAuthRepositoryImpl` (Auth + lectura del doc en `users/{uid}`).
- `FirestoreUsersRepositoryImpl` (colección `users`, fuente de verdad del
  estado del usuario para soft delete).
- `FirestoreCategoriesRepositoryImpl` (colección `categories`).
- `FirestoreExpensesRepositoryImpl` (colección `expenses`, con paginación
  cursor-based por `createdAt`).

En el primer registro se siembran 5 categorías por defecto (Comida,
Transporte, Entretenimiento, Hogar, Salud) vía
`seedDefaultCategories(userId)`.

### Índices de Firestore que ya hacen falta

- `expenses`: `userId ASC + createdAt DESC` (paginación de la home).
- `expenses`: `userId ASC + date ASC` (rango para estadísticas).
- `categories`: `userId ASC + titleLower ASC` (orden alfabético).

Los compuestos no son automáticos: se crean en consola o con
`firestore.indexes.json`. **El profe dijo explícitamente que esto va sí o sí.**

### Estructura de docs en Firestore

```
users/{userId}
  email: string
  displayName: string
  createdAt: timestamp

categories/{categoryId}
  userId: string
  title: string
  iconKey: string
  colorValue: number
  createdAt: timestamp

expenses/{expenseId}
  userId: string
  name: string
  categoryId: string
  amountArs: number
  originalAmount: number?
  currency: 'ars'|'usd'
  dolarType: string?
  date: timestamp
  attachmentUrl: string?
  createdAt: timestamp
  updatedAt: timestamp?
```

---

## 9. Conversión USD → ARS

Hoy: tabla local en `ExpenseFormNotifier.convertUsdToArs`. Es provisional y
**la vista no debería saberlo**, por eso el método vive en el notifier.

Cuando se conecte la API real (probablemente `dolarapi.com`), el método cambia
a un `Future<double>` que hace `http.get` y devuelve el monto convertido. El
front agarra eso porque el profe dijo "lógica de negocio en el front".

---

## 10. Estadísticas

`StatisticsNotifier` calcula dos cosas:

- **Pie chart** del mes seleccionado: agrupa gastos por `categoryId`, suma
  `amountArs`, y produce `List<CategorySlice>`.
- **Bar chart** del último año: agrupa por trimestre (`year-Qn`), suma totales,
  y produce `List<QuarterBar>`.

Las queries usan `getExpensesInRange(from, to)` — **necesita el índice
compuesto** `userId + date`.

---

## 11. Paginación de la home

`ExpensesListNotifier` usa cursor-based pagination con
`pageSize = 10` y como cursor el `createdAt` del último gasto cargado. La
home tiene un `ScrollController` que detecta proximidad al final de la lista
y dispara `loadMore`.

`getExpenses(userId, limit, lastCreatedAt)` se traduce a:

```dart
Query<Expense> q = db.collection('expenses')
  .where('userId', isEqualTo: userId)
  .orderBy('createdAt', descending: true)
  .limit(limit);
if (lastCreatedAt != null) q = q.startAfter([Timestamp.fromDate(lastCreatedAt)]);
```

Y eso necesita el **índice compuesto** `userId + createdAt DESC`.

---

## 12. Comandos útiles

```bash
flutter pub get                    # Instalar deps
flutter run                        # Correr en device/emu
flutter analyze                    # Linter (PASARLO antes de cualquier commit)
flutter test                       # Correr tests (faltan, ver PROGRESS.md)
flutter clean && flutter pub get   # Cuando algo raro pasa
```

---

## 13. Checklist antes de commitear

- [ ] `flutter analyze` sin warnings nuevos.
- [ ] La pantalla nueva sigue el patrón Screen → Notifier → State → Repository.
- [ ] No hay llamadas a repos desde widgets.
- [ ] Si agregaste una lista nueva, está paginada.
- [ ] Strings de UI en español, código en inglés.
- [ ] Cambios visibles probados en el flujo: login → home → form → details →
  estadísticas → perfil → logout.

---

## 14. Cosas que NO hay que hacer

- No usar `setState` para datos del dominio. Eso va en el notifier.
- No mezclar `StateNotifier` (legacy) con `Notifier`. Solo usar `Notifier`/`AutoDisposeNotifier`.
- No poner lógica de conversión, validación o filtrado en widgets. Eso va en
  notifiers o getters del state.
- No crear un backend custom. **Firebase para todo**.
- No olvidarse de los **índices de Firestore**.
- No romper el patrón. Si se rompe, primero se vuelve al patrón, después se
  continúa.
