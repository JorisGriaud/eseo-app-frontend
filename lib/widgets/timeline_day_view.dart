import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule_event.dart';
import '../providers/settings_provider.dart';
import '../config/event_style.dart';

/// Vue jour avec timeline verticale
class TimelineDayView extends StatelessWidget {
  final List<ScheduleEvent> events;
  final DateTime displayDate;

  const TimelineDayView({
    super.key,
    required this.events,
    required this.displayDate,
  });

  static const double timelineWidth = 40.0;
  static const int startHour = 8;
  static const int endHour = 18;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);
    final now = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        const topPadding = 8.0;
        final totalHours = endHour - startHour + 1;
        final hourHeight = (constraints.maxHeight - topPadding) / totalHours;

        return Padding(
          padding: const EdgeInsets.only(top: topPadding),
          child: Stack(
            children: [
              // Timeline et heures
              _buildTimeline(theme, hourHeight),
            // Ligne verticale continue
            Positioned(
              left: timelineWidth,
              top: 0,
              bottom: 0,
              child: Container(
                width: 1,
                color: theme.dividerColor,
              ),
            ),
            // Événements positionnés
            Positioned.fill(
              left: timelineWidth,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: Stack(
                  children: [
                    ..._buildEventCards(events, settings, theme, hourHeight),
                    // Indicateur de temps actuel
                    if (_shouldShowCurrentTimeIndicator(now, settings))
                      _buildCurrentTimeIndicator(theme, now, hourHeight),
                  ],
                ),
              ),
            ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeline(ThemeData theme, double hourHeight) {
    return Column(
      children: [
        for (int hour = startHour; hour <= endHour; hour++)
          SizedBox(
            height: hourHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label de l'heure
                SizedBox(
                  width: timelineWidth,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4, top: 2),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelSmall?.copyWith(
                        inherit: true,
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _buildEventCards(
    List<ScheduleEvent> events,
    SettingsProvider settings,
    ThemeData theme,
    double hourHeight,
  ) {
    return events.map((event) {
      final color = settings.getColorForCourseType(event.type);
      final top = _calculateEventTop(event.startTime, hourHeight);
      final height = _calculateEventHeight(event, hourHeight);

      final durationMinutes = event.endTime.difference(event.startTime).inMinutes;
      // isSingleLine : cours ≤ 45min — une seule ligne (ex: 30min)
      final isSingleLine = durationMinutes <= 45;
      // isCompact : cours entre 45min et 1h20 — horaire + titre sans salle/prof
      final isCompact = !isSingleLine && durationMinutes < 80;

      final textColor = _getEventTextColor(settings.eventStyle, color, theme);

      return Positioned(
        top: top,
        left: 0,
        right: 0,
        height: height,
        child: Builder(
          builder: (context) => GestureDetector(
            onTap: () => _showEventDetails(context, event, color, settings),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: _getEventDecoration(
                settings.eventStyle,
                color,
                theme,
                event.isHappening,
              ),
                child: Stack(
              children: [
                // Barre de couleur à gauche (uniquement pour le style leftBar)
                if (settings.eventStyle == EventStyle.leftBar)
                  Positioned(
                    left: 0,
                    top: 12,
                    bottom: 12,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                // Contenu
                if (isSingleLine)
                  // ≤ 45min : une seule ligne centrée verticalement
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${event.timeRange} : ${event.title}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          inherit: true,
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                else
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: isCompact ? 4 : 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Heure
                      Text(
                        event.timeRange,
                        style: theme.textTheme.bodySmall?.copyWith(
                          inherit: true,
                          color: textColor.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Titre
                      Flexible(
                        child: Text(
                          event.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            inherit: true,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Lieu et professeur (masqués si compact)
                      if (!isCompact) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (event.location.isNotEmpty) ...[
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: textColor.withOpacity(0.6),
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  event.location,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    inherit: true,
                                    fontSize: 11,
                                    color: textColor.withOpacity(0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            if (event.location.isNotEmpty && event.professor.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '•',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textColor.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            if (event.professor.isNotEmpty)
                              Flexible(
                                child: Text(
                                  event.professor,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    inherit: true,
                                    fontSize: 11,
                                    color: textColor.withOpacity(0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      );
    }).toList();
  }

  Widget _buildCurrentTimeIndicator(ThemeData theme, DateTime now, double hourHeight) {
    final top = _calculateEventTop(now, hourHeight);

    return Positioned(
      top: top - 10, // Aligné avec le centre de la ligne rouge
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            children: [
              // Label de l'heure actuelle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    inherit: true,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Point
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
              ),
              // Ligne horizontale
              Expanded(
                child: Container(
                  height: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateEventTop(DateTime time, double hourHeight) {
    final hour = time.hour;
    final minute = time.minute;
    final totalMinutes = (hour - startHour) * 60 + minute;
    return (totalMinutes / 60) * hourHeight;
  }

  double _calculateEventHeight(ScheduleEvent event, double hourHeight) {
    final durationMinutes = event.endTime.difference(event.startTime).inMinutes;
    return (durationMinutes / 60) * hourHeight;
  }

  bool _shouldShowCurrentTimeIndicator(DateTime now, SettingsProvider settings) {
    // Vérifier d'abord si l'heure est dans la plage affichée
    if (now.hour < startHour || now.hour > endHour) {
      return false;
    }

    // Ensuite vérifier les paramètres utilisateur
    return settings.shouldShowCurrentTimeIndicator(displayDate);
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

  BoxDecoration _getEventDecoration(
    EventStyle style,
    Color color,
    ThemeData theme,
    bool isHappening,
  ) {
    final boxShadow = isHappening
        ? [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ];

    switch (style) {
      case EventStyle.leftBar:
        return BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: boxShadow,
        );
      case EventStyle.filled:
        return BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: boxShadow,
        );
      case EventStyle.outlined:
        return BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
          boxShadow: boxShadow,
        );
      case EventStyle.filledLight:
        return BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
          boxShadow: boxShadow,
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
