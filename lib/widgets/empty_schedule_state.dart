import 'package:flutter/material.dart';

/// Empty state widget for when there are no courses
class EmptyScheduleState extends StatelessWidget {
  final bool isVacation;

  const EmptyScheduleState({
    super.key,
    this.isVacation = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Image.asset(
              'assets/ESEO-App.png',
              width: 80,
              height: 80,
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              isVacation ? 'Profite bien !' : 'Aucun cours prévu',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              isVacation
                  ? 'Aucun cours n\'est prévu pour le moment.\nProfite de ce temps libre !'
                  : 'Il n\'y a pas de cours aujourd\'hui.\nConsulte les jours suivants.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Illustration decoration
            if (isVacation)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDecoIcon(context, Icons.wb_sunny_outlined),
                  const SizedBox(width: 16),
                  _buildDecoIcon(context, Icons.local_cafe_outlined),
                  const SizedBox(width: 16),
                  _buildDecoIcon(context, Icons.headphones_outlined),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecoIcon(BuildContext context, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 24,
        color: theme.colorScheme.primary.withOpacity(0.7),
      ),
    );
  }
}
