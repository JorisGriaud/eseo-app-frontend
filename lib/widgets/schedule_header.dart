import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Header personnalisé avec navigation et switcher Jour/Semaine
class ScheduleHeader extends StatelessWidget {
  final DateTime displayDate;
  final String viewMode;
  final int? selectedDayIndex;
  final VoidCallback onPreviousDate;
  final VoidCallback onNextDate;
  final VoidCallback onTodayTap;
  final Function(String) onViewModeChanged;
  final Function(int) onDaySelected;
  final DateTime weekStart;

  const ScheduleHeader({
    super.key,
    required this.displayDate,
    required this.viewMode,
    required this.selectedDayIndex,
    required this.onPreviousDate,
    required this.onNextDate,
    required this.onTodayTap,
    required this.onViewModeChanged,
    required this.onDaySelected,
    required this.weekStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Navigation de date
            _buildDateNavigation(context, theme),
            const SizedBox(height: 16),
            // Switcher Jour/Semaine
            _buildViewSwitcher(context, theme),
            const SizedBox(height: 16),
            // Sélecteur de jours (visible uniquement en vue jour)
            if (viewMode == 'day') _buildDaySelector(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDateNavigation(BuildContext context, ThemeData theme) {
    String title;
    if (viewMode == 'day') {
      final dateFormat = DateFormat('EEEE d MMMM', 'fr_FR');
      title = dateFormat.format(displayDate);
      // Capitaliser la première lettre
      title = title[0].toUpperCase() + title.substring(1);
    } else {
      // Vue semaine: "9 – 13 févr. 2026 S6"
      final weekEnd = weekStart.add(const Duration(days: 4)); // Vendredi
      final startDay = DateFormat('d', 'fr_FR').format(weekStart);
      final endDay = DateFormat('d', 'fr_FR').format(weekEnd);
      final month = DateFormat('MMM', 'fr_FR').format(weekEnd);
      final year = DateFormat('y', 'fr_FR').format(weekEnd);
      final weekNumber = _getWeekNumber(weekStart);
      title = '$startDay – $endDay $month $year S$weekNumber';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: theme.colorScheme.primary),
            onPressed: onPreviousDate,
            padding: const EdgeInsets.all(8),
          ),
          Flexible(
            child: InkWell(
              onTap: onTodayTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    inherit: true,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: theme.colorScheme.primary),
            onPressed: onNextDate,
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSwitcher(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF25292e) : const Color(0xFFe5e7eb);
    final selectedColor = theme.colorScheme.surface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _buildSwitcherButton(
                context,
                theme,
                'Jour',
                viewMode == 'day',
                () => onViewModeChanged('day'),
                selectedColor,
              ),
            ),
            Expanded(
              child: _buildSwitcherButton(
                context,
                theme,
                'Semaine',
                viewMode == 'week',
                () => onViewModeChanged('week'),
                selectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitcherButton(
    BuildContext context,
    ThemeData theme,
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color selectedColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              inherit: true,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDaySelector(BuildContext context, ThemeData theme) {
    final dayNames = ['LUN', 'MAR', 'MER', 'JEU', 'VEN'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (index) {
          final dayDate = weekStart.add(Duration(days: index));
          final isSelected = selectedDayIndex == index;
          final isToday = _isToday(dayDate);

          return GestureDetector(
            onTap: () => onDaySelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  dayNames[index],
                  style: theme.textTheme.labelSmall?.copyWith(
                    inherit: true,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isToday
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  int _getWeekNumber(DateTime date) {
    final dayOfYear = int.parse(DateFormat('D').format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}
