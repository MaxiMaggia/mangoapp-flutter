import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../viewmodels/providers.dart';
import '../widgets/mango_logo.dart';
import 'dolar_rates_screen.dart';

// Pantalla de perfil: datos del usuario, accesos a config (categorias, dolar) y acciones de cuenta.
class ProfileScreen extends ConsumerWidget {
  static const name = 'ProfileScreen';
  const ProfileScreen({super.key});

  // Arma la UI del perfil (header, opciones de config y acciones de cuenta).
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
            subtitle: 'Ver tipos de cambio actuales',
            onTap: () => context.pushNamed(DolarRatesScreen.name),
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
          _SettingTile(
            icon: Icons.delete_forever,
            iconColor: AppColors.danger,
            title: 'Eliminar cuenta',
            subtitle: 'Eliminar tu cuenta y todos tus datos',
            onTap: () => _confirmDeleteAccount(context, ref),
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

  // Pide confirmacion, cierra sesion y manda al login.
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

  // Abre el dialogo de eliminar cuenta. El dialogo maneja todo su ciclo de
  // vida internamente (su propio ref y controller), por eso esto es minimo.
  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _DeleteAccountDialog(),
    );
  }
}

// Dialogo de eliminar cuenta como widget propio: tiene su propio ref y su
// TextEditingController manejado en initState/dispose. Asi Riverpod limpia
// las dependencias del dialogo solo cuando este muere, sin afectar al
// ProfileScreen (que es lo que causaba el crash `_dependents.isEmpty`).
class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_onChanged);
  }

  void _onChanged() => setState(() {}); // refresca el estado del botón

  @override
  void dispose() {
    _passwordCtrl.removeListener(_onChanged);
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await ref
          .read(authViewModelProvider.notifier)
          .deleteAccount(_passwordCtrl.text);
      // Éxito: NO hacemos pop manual. El authStateChanges limpia el user
      // y el router redirige al login desmontando esta pantalla.
    } catch (e) {
      // Error (ej: contraseña incorrecta). El diálogo sigue vivo.
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_isLoading && _passwordCtrl.text.trim().isNotEmpty;
    return AlertDialog(
      title: const Text('¿Eliminar cuenta?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Se van a marcar como eliminados tu usuario, tus gastos y '
            'tus categorías. Esta acción no se puede deshacer.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            autofocus: true,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'Confirmá tu contraseña',
              hintText: 'Ingresá tu contraseña',
              errorText: _errorText,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: canSubmit ? _handleDelete : null,
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.danger,
                  ),
                )
              : const Text('Eliminar'),
        ),
      ],
    );
  }
}

// Header del perfil con avatar (inicial), nombre y email sobre un degrade.
class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String email;
  const _ProfileHeader({required this.displayName, required this.email});

  @override
  Widget build(BuildContext context) {
    // Inicial para el avatar: del nombre, sino del email, sino "?".
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

// Encabezado de seccion en mayusculas (ej: "CONFIGURACION", "CUENTA").
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

// Item de la lista de opciones (icono + titulo + subtitulo) que dispara una accion al tocarlo.
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.mangoDeep;
    return Card(
      child: ListTile(
        onTap: onTap,
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
                subtitle!,
                style: const TextStyle(fontSize: 12),
              ),
        trailing: const Icon(Icons.chevron_right,
            color: AppColors.textSecondary),
      ),
    );
  }
}
