import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Header for a day section in the schedule
class DayHeader extends StatelessWidget {
  final DateTime date;

  const DayHeader({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    // Format: "Lundi 4 février"
    final dayName = DateFormat('EEEE', 'fr_FR').format(date);
    final dateStr = DateFormat('d MMMM', 'fr_FR').format(date);
    final capitalizedDayName = dayName[0].toUpperCase() + dayName.substring(1);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isToday ? theme.colorScheme.primary : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isToday ? theme.colorScheme.primary : theme.dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isToday ? Icons.today : Icons.calendar_today,
            size: 20,
            color: isToday ? Colors.white : theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            '$capitalizedDayName $dateStr',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isToday ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
          if (isToday) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Aujourd\'hui',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
