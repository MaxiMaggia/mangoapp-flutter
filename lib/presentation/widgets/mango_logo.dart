import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Logo de Mango: un mango estilizado + texto.
class MangoLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const MangoLogo({super.key, this.size = 48, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.mangoYellow, AppColors.mangoOrange],
            ),
            borderRadius: BorderRadius.circular(size / 3),
          ),
          child: Icon(
            Icons.savings_rounded,
            color: Colors.white,
            size: size * 0.55,
          ),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.25),
          Text(
            'Mango',
            style: TextStyle(
              fontSize: size * 0.55,
              fontWeight: FontWeight.w800,
              color: AppColors.mangoDeep,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}
