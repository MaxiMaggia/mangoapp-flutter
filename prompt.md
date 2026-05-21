Cuando un usuario se registra en la app por primera vez, queremos crearle 
automáticamente 5 categorías base en Firestore para que la app no esté 
vacía. Estas categorías son tratadas como cualquier otra categoría del 
usuario: puede editarlas, borrarlas, agregar más.

Las 5 categorías son:

  1. Comida (iconKey: 'food', colorValue: 0xFFEF4444)
  2. Transporte (iconKey: 'transport', colorValue: 0xFF3B82F6)
  3. Entretenimiento (iconKey: 'entertainment', colorValue: 0xFFA855F7)
  4. Hogar (iconKey: 'home', colorValue: 0xFF10B981)
  5. Salud (iconKey: 'health', colorValue: 0xFF14B8A6)

DISEÑO:

1. Agregar a la interface `CategoriesRepository` un nuevo método:

```dart
   Future<void> seedDefaultCategories(String userId);
```

2. Implementarlo en `FirestoreCategoriesRepositoryImpl` usando un 
   `WriteBatch` de Firestore para que las 5 escrituras sean atómicas 
   (todas o ninguna):

```dart
   @override
   Future<void> seedDefaultCategories(String userId) async {
     final batch = FirebaseFirestore.instance.batch();
     final now = DateTime.now();
     final defaults = [
       Category(userId: userId, title: 'Comida', iconKey: 'food', 
                colorValue: 0xFFEF4444, createdAt: now),
       Category(userId: userId, title: 'Transporte', iconKey: 'transport', 
                colorValue: 0xFF3B82F6, createdAt: now),
       Category(userId: userId, title: 'Entretenimiento', 
                iconKey: 'entertainment', colorValue: 0xFFA855F7, 
                createdAt: now),
       Category(userId: userId, title: 'Hogar', iconKey: 'home', 
                colorValue: 0xFF10B981, createdAt: now),
       Category(userId: userId, title: 'Salud', iconKey: 'health', 
                colorValue: 0xFF14B8A6, createdAt: now),
     ];
     for (final cat in defaults) {
       final ref = _col.doc();  // genera ID nuevo
       batch.set(ref, cat);
     }
     await batch.commit();
   }
```

3. Implementarlo también en `FakeCategoriesRepository` (puede ser 
   no-op o agregar las 5 al list en memoria, lo que sea más simple).

4. En `FirebaseAuthRepositoryImpl`, INYECTAR el 
   `CategoriesRepository` por constructor:

```dart
   class FirebaseAuthRepositoryImpl implements AuthRepository {
     final CategoriesRepository _categoriesRepo;
     FirebaseAuthRepositoryImpl(this._categoriesRepo);
     // ...
   }
```

5. En el método `signUp` de `FirebaseAuthRepositoryImpl`, después de 
   crear el usuario en Firebase Auth y antes de devolverlo, llamar 
   a `_categoriesRepo.seedDefaultCategories(user.uid)`. ENVOLVER esta 
   llamada en try/catch interno: si falla, NO propagar el error (el 
   usuario ya está creado, no queremos hacerlo loguearse de nuevo). 
   Solo loggear el error con `print` para que sepamos si pasó.

```dart
   try {
     await _categoriesRepo.seedDefaultCategories(_auth.currentUser!.uid);
   } catch (e) {
     print('Warning: no se pudo crear el seed de categorías: $e');
   }
```

6. Actualizar `lib/data/providers.dart` para que el 
   `authRepositoryProvider` reciba el `categoriesRepositoryProvider` 
   como dependencia:

```dart
   final authRepositoryProvider = Provider<AuthRepository>(
     (ref) => FirebaseAuthRepositoryImpl(
       ref.read(categoriesRepositoryProvider),
     ),
   );
```

7. NO hacer seeding en `signIn`, SOLO en `signUp`. Si querés podés 
   pensar en una migración para usuarios viejos que no tienen 
   categorías, pero no lo implementes — confirmame antes.

8. Correr `flutter analyze` al final.