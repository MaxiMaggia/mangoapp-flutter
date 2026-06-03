import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app_router.dart';
import 'core/app_theme.dart';
import 'firebase_options.dart';

// Punto de entrada de la app: deja todo listo antes de arrancar.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Cargamos los formatos de fecha/numero en español de Argentina.
  await initializeDateFormatting('es_AR');
  // Inicializamos Firebase con la config de la plataforma actual.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // ProviderScope: arranca Riverpod para que todos los providers esten disponibles.
  runApp(const ProviderScope(child: MangoApp()));
}

// El widget raiz: enchufa el tema y el router de la app.
class MangoApp extends ConsumerWidget {
  const MangoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Mango',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
