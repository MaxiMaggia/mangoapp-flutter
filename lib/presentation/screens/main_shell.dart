import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../viewmodels/providers.dart';

// Cascaron con la barra inferior que envuelve las tres secciones (Home, Estadisticas, Perfil).
class MainShell extends ConsumerWidget {
  // Maneja las ramas de navegacion del go_router (cada tab es una rama).
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  // Arma el Scaffold con la rama activa y el BottomNavigationBar.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) {
          // Cambia de tab; si tocas la misma vuelve a su raiz (initialLocation).
          navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          );
          // Al entrar a Estadisticas (tab 1) refrescamos sus datos.
          if (i == 1) {
            ref.read(statisticsViewModelProvider.notifier).load();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: 'Estadisticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
