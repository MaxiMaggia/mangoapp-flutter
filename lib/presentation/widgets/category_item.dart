import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../core/app_theme.dart';
import '../../domain/category.dart';
import '../utils/category_icons.dart';

/// Tile de categoria con acciones de editar/eliminar (lista de categorias).
class CategoryItem extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryItem({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Slidable: si deslizas el tile hacia la izquierda aparecen Editar y Eliminar.
    return Slidable(
      key: ValueKey(category.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: AppColors.mangoYellow,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Editar',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Eliminar',
          ),
        ],
      ),
      child: Card(
        child: ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              CategoryIcons.iconFor(category.iconKey),
              color: category.color,
            ),
          ),
          title: Text(
            category.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right,
              color: AppColors.textSecondary),
          onTap: onEdit,
        ),
      ),
    );
  }
}

/// Chip de categoria para mostrar en filtros, etc.
class CategoryChipBadge extends StatelessWidget {
  final Category category;
  final bool selected;
  final VoidCallback? onTap;

  const CategoryChipBadge({
    super.key,
    required this.category,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? category.color.withOpacity(0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? category.color : Colors.black.withOpacity(0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CategoryIcons.iconFor(category.iconKey),
              size: 16,
              color: category.color,
            ),
            const SizedBox(width: 6),
            Text(
              category.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? category.color : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
