import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/schedule_event.dart';
import '../providers/settings_provider.dart';
import '../config/event_style.dart';

/// Week calendar view with grid and time slots
class WeekCalendarView extends StatelessWidget {
  final DateTime startOfWeek;
  final List<ScheduleEvent> events;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  const WeekCalendarView({
    super.key,
    required this.startOfWeek,
    required this.events,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  @override
  Widget build(BuildContext context) {
    final weekDays = _getWeekDays(startOfWeek);
    final settings = Provider.of<SettingsProvider>(context);

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _buildCalendarGrid(context, weekDays, settings),
      ),
    );
  }

  Widget _buildCalendarGrid(
    BuildContext context,
    List<DateTime> weekDays,
    SettingsProvider settings,
  ) {
    const minuteHeight = 1.0;
    const dayWidth = 120.0;
    const timeColumnWidth = 60.0;
    const startHour = 8;
    const endHour = 19;
    const totalMinutes = (endHour - startHour) * 60;
    final gridHeight = totalMinutes * minuteHeight;

    return SizedBox(
      width: timeColumnWidth + (dayWidth * 5),
      child: Column(
        children: [
          // Days header
          _buildDaysHeader(context, weekDays, dayWidth, timeColumnWidth),

          // Grid with time labels and events
          SizedBox(
            height: gridHeight,
            child: Stack(
              children: [
                // Background grid
                _buildBackgroundGrid(
                  context,
                  startHour,
                  endHour,
                  dayWidth,
                  timeColumnWidth,
                  minuteHeight,
                ),

                // Ligne verticale continue après la colonne des heures
                Positioned(
                  left: timeColumnWidth - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1,
                    color: Theme.of(context).dividerColor,
                  ),
                ),

                // Events overlay
                Row(
                  children: [
                    SizedBox(width: timeColumnWidth),
                    ...weekDays.map((day) {
                      return SizedBox(
                        width: dayWidth,
                        child: _buildDayEvents(
                          context,
                          day,
                          startHour,
                          minuteHeight,
                          settings,
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysHeader(
    BuildContext context,
    List<DateTime> weekDays,
    double dayWidth,
    double timeColumnWidth,
  ) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayNames = ['LUN', 'MAR', 'MER', 'JEU', 'VEN'];

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          // Coin haut gauche
          Container(
            width: timeColumnWidth,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: theme.dividerColor),
              ),
            ),
          ),
          // Headers des jours
          ...List.generate(weekDays.length, (index) {
            final day = weekDays[index];
            final isToday = DateTime(day.year, day.month, day.day) == today;
            return Container(
              width: dayWidth,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Center(
                child: Text(
                  dayNames[index],
                  style: theme.textTheme.labelMedium?.copyWith(
                    inherit: true,
                    fontWeight: FontWeight.w600,
                    color: isToday
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBackgroundGrid(
    BuildContext context,
    int startHour,
    int endHour,
    double dayWidth,
    double timeColumnWidth,
    double minuteHeight,
  ) {
    final theme = Theme.of(context);
    final hours = List.generate(endHour - startHour, (i) => startHour + i);

    return Column(
      children: hours.map((hour) {
        final hourHeight = 60 * minuteHeight;
        return SizedBox(
          height: hourHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time label
              Container(
                width: timeColumnWidth,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.labelSmall?.copyWith(
                      inherit: true,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),

              // Day cells
              Expanded(
                child: Row(
                  children: List.generate(5, (dayIndex) {
                    return Container(
                      width: dayWidth,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: theme.dividerColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayEvents(
    BuildContext context,
    DateTime day,
    int startHour,
    double minuteHeight,
    SettingsProvider settings,
  ) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // Get events for this day
    final dayEvents = events.where((event) {
      return event.startTime.isAfter(dayStart) &&
          event.startTime.isBefore(dayEnd);
    }).toList();

    if (dayEvents.isEmpty) return const SizedBox();

    return Stack(
      children: dayEvents.map((event) {
        return _buildPositionedEvent(
          context,
          event,
          startHour,
          minuteHeight,
          settings,
        );
      }).toList(),
    );
  }

  Widget _buildPositionedEvent(
    BuildContext context,
    ScheduleEvent event,
    int startHour,
    double minuteHeight,
    SettingsProvider settings,
  ) {
    final theme = Theme.of(context);
    final color = settings.getColorForCourseType(event.type);

    // Calculate position
    final eventStart = event.startTime;
    final eventEnd = event.endTime;

    // Minutes from start of grid (8:00 AM)
    final startMinutes =
        (eventStart.hour - startHour) * 60 + eventStart.minute;
    final durationMinutes = eventEnd.difference(eventStart).inMinutes;

    final top = startMinutes * minuteHeight;
    final height = durationMinutes * minuteHeight;

    return Positioned(
      top: top + 1,
      left: 2,
      right: 2,
      height: height - 2,
      child: GestureDetector(
        onTap: () => _showEventDetails(context, event, color, settings),
        child: Container(
          decoration: _getEventDecoration(settings.eventStyle, color, theme),
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                event.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  inherit: true,
                  fontWeight: FontWeight.bold,
                  color: _getEventTextColor(settings.eventStyle, color, theme),
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventDetails(
    BuildContext context,
    ScheduleEvent event,
    Color color,
    SettingsProvider settings,
  ) {
    final theme = Theme.of(context);
    final typeLabel = settings.getLabelForCourseType(event.type);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Type de cours avec badge coloré
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color, width: 1),
                  ),
                  child: Text(
                    typeLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      inherit: true,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Titre
            Text(
              event.title,
              style: theme.textTheme.titleLarge?.copyWith(
                inherit: true,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            // Horaires
            _buildDetailRow(
              context,
              Icons.access_time,
              'Horaires',
              event.timeRange,
              theme,
            ),
            const SizedBox(height: 16),
            // Lieu
            if (event.location.isNotEmpty)
              _buildDetailRow(
                context,
                Icons.location_on_outlined,
                'Salle',
                event.location,
                theme,
              ),
            if (event.location.isNotEmpty) const SizedBox(height: 16),
            // Professeur
            if (event.professor.isNotEmpty)
              _buildDetailRow(
                context,
                Icons.person_outline,
                'Professeur',
                event.professor,
                theme,
              ),
            if (event.professor.isNotEmpty) const SizedBox(height: 16),
            // Description (si disponible)
            if (event.description != null && event.description!.isNotEmpty) ...[
              _buildDetailRow(
                context,
                Icons.description_outlined,
                'Description',
                event.description!,
                theme,
              ),
              const SizedBox(height: 16),
            ],
            // Durée
            _buildDetailRow(
              context,
              Icons.timer_outlined,
              'Durée',
              '${event.durationMinutes} minutes',
              theme,
            ),
            const SizedBox(height: 24),
            // Bouton fermer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Fermer'),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  inherit: true,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  inherit: true,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<DateTime> _getWeekDays(DateTime start) {
    final days = <DateTime>[];
    for (int i = 0; i < 5; i++) {
      days.add(start.add(Duration(days: i)));
    }
    return days;
  }

  BoxDecoration _getEventDecoration(EventStyle style, Color color, ThemeData theme) {
    switch (style) {
      case EventStyle.leftBar:
        return BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(color: color, width: 3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        );
      case EventStyle.filled:
        return BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        );
      case EventStyle.outlined:
        return BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color, width: 2),
        );
      case EventStyle.filledLight:
        return BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color, width: 2),
        );
    }
  }

  Color _getEventTextColor(EventStyle style, Color color, ThemeData theme) {
    switch (style) {
      case EventStyle.filled:
        return Colors.white;
      default:
        return theme.colorScheme.onSurface;
    }
  }
}
