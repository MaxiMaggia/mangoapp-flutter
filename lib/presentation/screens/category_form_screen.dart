import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../utils/base_screen_state.dart';
import '../utils/category_icons.dart';
import '../viewmodels/providers.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  static const nameNew = 'CategoryFormScreenNew';
  static const nameEdit = 'CategoryFormScreenEdit';

  final String? categoryId;
  const CategoryFormScreen({super.key, this.categoryId});

  @override
  ConsumerState<CategoryFormScreen> createState() =>
      _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _titleCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _iconKey = CategoryIcons.other.key;
  int _colorValue = CategoryColors.palette.first;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.categoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(categoryFormViewModelProvider.notifier)
            .loadCategory(widget.categoryId!);
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    ref.read(categoryFormViewModelProvider.notifier).save(
          title: _titleCtrl.text.trim(),
          iconKey: _iconKey,
          colorValue: _colorValue,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryFormViewModelProvider);

    if (state.category != null && !_initialized) {
      _initialized = true;
      _titleCtrl.text = state.category!.title;
      _iconKey = state.category!.iconKey;
      _colorValue = state.category!.colorValue;
    }

    ref.listen(categoryFormViewModelProvider, (_, next) {
      if (next.wasSaved) {
        Navigator.of(context).pop(true);
      }
      if (next.screenState.isError) {
        final msg = next.screenState.errorMessage;
        if (msg != null && msg.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
          );
        }
      }
    });

    final selectedColor = Color(_colorValue);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.isEditing ? 'Editar categoria' : 'Nueva categoria'),
        actions: [
          TextButton(
            onPressed: state.screenState.isLoading ? null : _submit,
            child: const Text('Guardar',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: state.screenState.isLoading,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // Preview
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: selectedColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Icon(
                        CategoryIcons.iconFor(_iconKey),
                        size: 48,
                        color: selectedColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _titleCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Ej: Comida, Transporte...',
                      errorText: state.titleError ? 'Requerido' : null,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel('Icono'),
                  const SizedBox(height: 8),
                  _IconGrid(
                    selected: _iconKey,
                    color: selectedColor,
                    onTap: (key) => setState(() => _iconKey = key),
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel('Color'),
                  const SizedBox(height: 8),
                  _ColorPalette(
                    selected: _colorValue,
                    onTap: (value) => setState(() => _colorValue = value),
                  ),
                ],
              ),
            ),
          ),
          if (state.screenState.isLoading)
            Container(
              color: Colors.black.withOpacity(0.05),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _IconGrid extends StatelessWidget {
  final String selected;
  final Color color;
  final ValueChanged<String> onTap;
  const _IconGrid({
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: CategoryIcons.all.map((option) {
        final isSelected = option.key == selected;
        return GestureDetector(
          onTap: () => onTap(option.key),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.15) : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.black.withOpacity(0.06),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              option.icon,
              color: isSelected ? color : AppColors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ColorPalette extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _ColorPalette({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: CategoryColors.palette.map((value) {
        final color = Color(value);
        final isSelected = value == selected;
        return GestureDetector(
          onTap: () => onTap(value),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
