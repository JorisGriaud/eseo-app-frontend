import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/schedule_header.dart';
import '../widgets/timeline_day_view.dart';
import '../widgets/empty_schedule_state.dart';
import '../widgets/error_display.dart';
import '../widgets/week_calendar_view.dart';
import 'login_screen.dart';

/// Schedule tab with Smart Day logic
class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  DateTime? _selectedDate;
  DateTime _currentWeekStart = _getMondayOfWeek(DateTime.now());
  String _viewMode = 'day'; // 'day' ou 'week'
  int? _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    // Initialiser le jour sélectionné à aujourd'hui
    final now = DateTime.now();
    // 0 = Lundi, 4 = Vendredi (pas de samedi/dimanche)
    _selectedDayIndex = now.weekday <= 5 ? now.weekday - 1 : 0;

    // Fetch schedule on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ScheduleProvider>(context, listen: false).fetchSchedule();
    });
  }

  /// Get Monday of the current week (or next Monday if weekend)
  static DateTime _getMondayOfWeek(DateTime date) {
    // Normaliser la date à minuit
    final normalizedDate = DateTime(date.year, date.month, date.day);

    if (date.weekday == DateTime.saturday) {
      // Si samedi, aller au lundi suivant (+2 jours)
      return normalizedDate.add(const Duration(days: 2));
    } else if (date.weekday == DateTime.sunday) {
      // Si dimanche, aller au lundi suivant (+1 jour)
      return normalizedDate.add(const Duration(days: 1));
    }

    // Pour les jours de semaine, trouver le lundi de cette semaine
    final daysToSubtract = date.weekday - DateTime.monday;
    return normalizedDate.subtract(Duration(days: daysToSubtract));
  }

  Future<void> _handleRefresh() async {
    await Provider.of<ScheduleProvider>(context, listen: false)
        .refreshSchedule();
    setState(() {
      _selectedDate = null; // Reset to smart date
    });
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final scheduleProvider =
        Provider.of<ScheduleProvider>(context, listen: false);

    scheduleProvider.clear();
    await authProvider.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _goToPreviousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });

    // Charger les données pour la nouvelle semaine si nécessaire
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    scheduleProvider.ensureDataForDate(_currentWeekStart);
  }

  void _goToNextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });

    // Charger les données pour la nouvelle semaine si nécessaire
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    scheduleProvider.ensureDataForDate(_currentWeekStart);
  }

  void _goToToday() {
    setState(() {
      _selectedDate = null;
      _currentWeekStart = _getMondayOfWeek(DateTime.now());
      final now = DateTime.now();
      // Si on est samedi (6) ou dimanche (7), on va au lundi
      _selectedDayIndex = now.weekday <= 5 ? now.weekday - 1 : 0;
    });

    // Charger les données pour aujourd'hui si nécessaire
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    scheduleProvider.ensureDataForDate(DateTime.now());
  }

  void _onViewModeChanged(String mode) {
    setState(() {
      _viewMode = mode;
    });
  }

  void _onDaySelected(int dayIndex) {
    // Valider que l'index est entre 0 (lundi) et 4 (vendredi)
    if (dayIndex < 0 || dayIndex > 4) return;

    final newDate = _currentWeekStart.add(Duration(days: dayIndex));

    setState(() {
      _selectedDayIndex = dayIndex;
      _selectedDate = newDate;
    });

    // Charger les données pour le jour sélectionné si nécessaire
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    scheduleProvider.ensureDataForDate(newDate);
  }

  void _onPreviousDate() {
    DateTime? newDate;

    setState(() {
      if (_viewMode == 'day') {
        // S'assurer que _selectedDayIndex est initialisé
        _selectedDayIndex ??= 0;

        // Si on est après lundi (index > 0), on recule d'un jour
        if (_selectedDayIndex! > 0) {
          _selectedDayIndex = _selectedDayIndex! - 1;
          newDate = _currentWeekStart.add(Duration(days: _selectedDayIndex!));
          _selectedDate = newDate;
        } else {
          // Si on est lundi (index == 0), passer au vendredi de la semaine précédente
          _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
          _selectedDayIndex = 4; // Vendredi
          newDate = _currentWeekStart.add(const Duration(days: 4));
          _selectedDate = newDate;
        }
      } else {
        _goToPreviousWeek();
        newDate = _currentWeekStart;
      }
    });

    // Charger les données pour la nouvelle date si nécessaire
    if (newDate != null) {
      final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
      scheduleProvider.ensureDataForDate(newDate!);
    }
  }

  void _onNextDate() {
    DateTime? newDate;

    setState(() {
      if (_viewMode == 'day') {
        // S'assurer que _selectedDayIndex est initialisé
        _selectedDayIndex ??= 0;

        // Si on est avant vendredi (index < 4), on avance d'un jour
        if (_selectedDayIndex! < 4) {
          _selectedDayIndex = _selectedDayIndex! + 1;
          newDate = _currentWeekStart.add(Duration(days: _selectedDayIndex!));
          _selectedDate = newDate;
        } else {
          // Si on est vendredi (index == 4), passer au lundi de la semaine suivante
          _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
          _selectedDayIndex = 0; // Lundi
          newDate = _currentWeekStart;
          _selectedDate = newDate;
        }
      } else {
        _goToNextWeek();
        newDate = _currentWeekStart;
      }
    });

    // Charger les données pour la nouvelle date si nécessaire
    if (newDate != null) {
      final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
      scheduleProvider.ensureDataForDate(newDate!);
    }
  }

  Future<void> _selectDate() async {
    final scheduleProvider =
        Provider.of<ScheduleProvider>(context, listen: false);
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 90)), // 3 mois avant
      lastDate: now.add(const Duration(days: 365)), // 1 an après
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _currentWeekStart = _getMondayOfWeek(picked);
        _selectedDayIndex = picked.weekday - 1;
      });

      // Charger les données pour la date sélectionnée si nécessaire
      await scheduleProvider.ensureDataForDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ScheduleProvider>(
        builder: (context, scheduleProvider, child) {
          // Déterminer la date à afficher
          DateTime displayDate;
          if (_selectedDate != null) {
            displayDate = _selectedDate!;
          } else if (_selectedDayIndex != null) {
            displayDate = _currentWeekStart.add(Duration(days: _selectedDayIndex!));
          } else {
            displayDate = scheduleProvider.getSmartDisplayDate() ?? DateTime.now();
          }

          return Column(
            children: [
              // Header personnalisé
              ScheduleHeader(
                displayDate: displayDate,
                viewMode: _viewMode,
                selectedDayIndex: _selectedDayIndex,
                onPreviousDate: _onPreviousDate,
                onNextDate: _onNextDate,
                onTodayTap: _goToToday,
                onViewModeChanged: _onViewModeChanged,
                onDaySelected: _onDaySelected,
                weekStart: _currentWeekStart,
              ),

              // Contenu principal
              Expanded(
                child: _buildMainContent(scheduleProvider, displayDate),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainContent(ScheduleProvider scheduleProvider, DateTime displayDate) {
    // Loading state
    if (scheduleProvider.isLoading && scheduleProvider.events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (scheduleProvider.error != null && scheduleProvider.events.isEmpty) {
      return ErrorDisplay(
        message: scheduleProvider.error!,
        onRetry: () => scheduleProvider.fetchSchedule(),
      );
    }

    // Empty state (no courses at all)
    if (scheduleProvider.events.isEmpty) {
      return const EmptyScheduleState(isVacation: true);
    }

    // Display based on view mode
    if (_viewMode == 'week') {
      return WeekCalendarView(
        startOfWeek: _currentWeekStart,
        events: scheduleProvider.events,
        onPreviousWeek: _goToPreviousWeek,
        onNextWeek: _goToNextWeek,
      );
    } else {
      // Day view with timeline
      return _buildTimelineDayView(scheduleProvider, displayDate);
    }
  }

  Widget _buildTimelineDayView(ScheduleProvider scheduleProvider, DateTime displayDate) {
    // Get events for the selected date
    final dayEvents = scheduleProvider.getEventsForDate(displayDate);

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: dayEvents.isEmpty
          ? const EmptyScheduleState(isVacation: false)
          : TimelineDayView(
              events: dayEvents,
              displayDate: displayDate,
            ),
    );
  }
}
