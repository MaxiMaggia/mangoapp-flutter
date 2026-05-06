import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../viewmodels/providers.dart';
import '../widgets/mango_logo.dart';

class ProfileScreen extends ConsumerWidget {
  static const name = 'ProfileScreen';
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _ProfileHeader(
            displayName: user?.displayName ?? '',
            email: user?.email ?? '',
          ),
          const SizedBox(height: 24),
          _SectionHeader(text: 'Configuracion'),
          const SizedBox(height: 8),
          _SettingTile(
            icon: Icons.category_outlined,
            title: 'Administrar categorias',
            subtitle: 'Crear, editar y eliminar categorias',
            onTap: () => context.push('/categories'),
          ),
          _SettingTile(
            icon: Icons.attach_money,
            title: 'Cotizacion del dolar',
            subtitle: 'Definir tipo de cambio por defecto',
            enabled: false,
            onTap: () {},
          ),
          _SettingTile(
            icon: Icons.notifications_outlined,
            title: 'Notificaciones',
            subtitle: 'Recordatorios de gastos',
            enabled: false,
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _SectionHeader(text: 'Cuenta'),
          const SizedBox(height: 8),
          _SettingTile(
            icon: Icons.logout,
            iconColor: AppColors.danger,
            title: 'Cerrar sesion',
            onTap: () => _confirmLogout(context, ref),
          ),
          const SizedBox(height: 24),
          const Center(child: MangoLogo(size: 32)),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'v0.1.0 · Hecho con flutter',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesion'),
        content: const Text('¿Seguro que querés salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authViewModelProvider.notifier).signOut();
      if (context.mounted) context.go('/login');
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String email;
  const _ProfileHeader({required this.displayName, required this.email});

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : '?');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.mangoYellow, AppColors.mangoOrange],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mangoDeep,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName.isNotEmpty ? displayName : 'Usuario',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool enabled;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.mangoDeep;
    return Card(
      child: ListTile(
        enabled: enabled,
        onTap: enabled ? onTap : null,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                enabled ? subtitle! : '$subtitle (proximamente)',
                style: const TextStyle(fontSize: 12),
              ),
        trailing: enabled
            ? const Icon(Icons.chevron_right,
                color: AppColors.textSecondary)
            : null,
      ),
    );
  }
}
