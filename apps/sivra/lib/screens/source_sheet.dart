import 'package:flutter/material.dart';

import '../design/sivra_colors.dart';
import '../models/drill_item.dart';

class SourceSheet extends StatelessWidget {
  final DrillItemSource source;

  const SourceSheet({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              SivraColors.surfaceSoft,
              SivraColors.deepInk,
              SivraColors.ritualGradientBottom,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SOURCE CONTEXT',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: SivraColors.bronze,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: SivraColors.bronze.withValues(alpha: 0.1),
                  border: Border.all(
                    color: SivraColors.bronze.withValues(alpha: 0.24),
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'VERIFIED SOURCE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: SivraColors.bronze,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                source.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                '${source.publisher} • ${source.dateLabel}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: SivraColors.mutedText),
              ),
              if (source.snippet != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SivraColors.surface.withValues(alpha: 0.72),
                    border: Border.all(
                      color: SivraColors.bronze.withValues(alpha: 0.14),
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    source.snippet!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: SivraColors.bronze,
                        foregroundColor: SivraColors.deepInk,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
