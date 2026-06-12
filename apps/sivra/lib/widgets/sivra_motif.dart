import 'package:flutter/material.dart';

import '../design/sivra_colors.dart';

class SivraMotif extends StatelessWidget {
  final double width;

  const SivraMotif({super.key, this.width = 148});

  @override
  Widget build(BuildContext context) {
    const bronze = SivraColors.bronze;

    return Semantics(
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: 20,
        child: Row(
          children: [
            Expanded(child: _MotifLine()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                width: 8,
                height: 8,
                transform: Matrix4.rotationZ(0.785398),
                decoration: BoxDecoration(
                  color: bronze.withValues(alpha: 0.38),
                  border: Border.all(
                    color: bronze.withValues(alpha: 0.72),
                    width: 0.7,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: bronze.withValues(alpha: 0.24),
                      blurRadius: 9,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: _MotifLine()),
          ],
        ),
      ),
    );
  }
}

class _MotifLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.7,
      decoration: BoxDecoration(
        color: SivraColors.bronze.withValues(alpha: 0.38),
        boxShadow: [
          BoxShadow(
            color: SivraColors.bronze.withValues(alpha: 0.16),
            blurRadius: 5,
          ),
        ],
      ),
    );
  }
}
