import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/schedule_event.dart';
import '../services/api_service.dart';

/// Schedule state provider
class ScheduleProvider with ChangeNotifier {
  List<ScheduleEvent> _events = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetch;
  DateTime? _loadedStart; // Date de début des données chargées
  DateTime? _loadedEnd; // Date de fin des données chargées

  List<ScheduleEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastFetch => _lastFetch;
  DateTime? get loadedStart => _loadedStart;
  DateTime? get loadedEnd => _loadedEnd;

  /// Get events grouped by day
  Map<DateTime, List<ScheduleEvent>> get eventsByDay {
    final Map<DateTime, List<ScheduleEvent>> grouped = {};

    for (var event in _events) {
      final date = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );

      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(event);
    }

    // Sort events within each day by start time
    grouped.forEach((date, events) {
      events.sort((a, b) => a.startTime.compareTo(b.startTime));
    });

    return grouped;
  }

  /// Fetch schedule from backend
  /// Charge par défaut 3 mois de données à partir d'aujourd'hui
  Future<void> fetchSchedule({
    bool force = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Don't fetch if already loading
    if (_isLoading) return;

    // Calculer les dates par défaut (3 mois à partir d'aujourd'hui)
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, now.day);
    final end = endDate ?? start.add(const Duration(days: 90)); // 3 mois

    // Check if we need to fetch (cache is less than 1 hour old and covers the requested range)
    if (!force && _lastFetch != null && _loadedStart != null && _loadedEnd != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetch!);
      final coversRange = _loadedStart!.isBefore(start.add(const Duration(days: 1))) &&
          _loadedEnd!.isAfter(end.subtract(const Duration(days: 1)));

      if (timeSinceLastFetch.inHours < 1 && coversRange) {
        return; // Use cached data
      }
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Format dates for API (YYYY-MM-DD)
      final startStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      final endStr = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

      // Build endpoint with date parameters
      String endpoint = '${ApiConfig.agenda}?start=$startStr&end=$endStr';
      if (force) {
        endpoint += '&force=true';
      }

      final response = await ApiService.get(endpoint);
      final data = ApiService.handleResponse(response);

      // Parse schedule events (new API returns 'events' instead of 'schedule')
      final eventsList = data['events'] as List;
      _events = eventsList
          .map((json) => ScheduleEvent.fromJson(json))
          .toList();

      // Sort events by start time
      _events.sort((a, b) => a.startTime.compareTo(b.startTime));

      // Remove overlapping events, keeping the most recent modification
      _events = _removeOverlappingEvents(_events);

      _lastFetch = DateTime.now();
      _loadedStart = start;
      _loadedEnd = end;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh schedule (force fetch)
  Future<void> refreshSchedule() async {
    await fetchSchedule(force: true);
  }

  /// Ensure data is loaded for a specific date
  /// Charge automatiquement plus de données si nécessaire
  Future<void> ensureDataForDate(DateTime date) async {
    // Si pas de données chargées, charger 3 mois à partir de cette date
    if (_loadedStart == null || _loadedEnd == null) {
      await fetchSchedule(startDate: date, endDate: date.add(const Duration(days: 90)));
      return;
    }

    final targetDate = DateTime(date.year, date.month, date.day);

    // Vérifier si la date est dans la plage chargée
    if (targetDate.isBefore(_loadedStart!) || targetDate.isAfter(_loadedEnd!)) {
      // Charger une nouvelle plage centrée autour de cette date
      // 1 mois avant, 2 mois après
      final newStart = targetDate.subtract(const Duration(days: 30));
      final newEnd = targetDate.add(const Duration(days: 60));
      await fetchSchedule(startDate: newStart, endDate: newEnd, force: true);
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Remove overlapping events, keeping the most recently modified one.
  ///
  /// Two events overlap if one starts strictly before the other ends
  /// (touching at the same time — e.g. end A == start B — is NOT an overlap).
  ///
  /// The event with the most recent [lastModified] date wins.
  /// If neither event has [lastModified], both are kept as-is.
  List<ScheduleEvent> _removeOverlappingEvents(List<ScheduleEvent> events) {
    // Work on a copy sorted by start time
    final sorted = List<ScheduleEvent>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final result = <ScheduleEvent>[];

    for (final candidate in sorted) {
      // Find all events in result that truly overlap with candidate
      final overlappingIndices = <int>[];
      for (int i = 0; i < result.length; i++) {
        final existing = result[i];
        final overlaps = candidate.startTime.isBefore(existing.endTime) &&
            candidate.endTime.isAfter(existing.startTime);
        if (overlaps) overlappingIndices.add(i);
      }

      if (overlappingIndices.isEmpty) {
        // No conflict — just add
        result.add(candidate);
      } else {
        // Decide whether candidate beats every conflicting event
        bool candidateWinsAll = true;
        for (final i in overlappingIndices) {
          if (!_isMoreRecent(candidate, result[i])) {
            candidateWinsAll = false;
            break;
          }
        }

        if (candidateWinsAll) {
          // Remove all conflicting events and add candidate
          for (final i in overlappingIndices.reversed) {
            result.removeAt(i);
          }
          result.add(candidate);
        }
        // Otherwise keep existing events, discard candidate
      }
    }

    result.sort((a, b) => a.startTime.compareTo(b.startTime));
    return result;
  }

  /// Returns true if [a] should replace [b] when they overlap.
  ///
  /// Only uses [lastModified] — if not available on both, keeps existing ([b]).
  bool _isMoreRecent(ScheduleEvent a, ScheduleEvent b) {
    if (a.lastModified != null && b.lastModified != null) {
      return a.lastModified!.isAfter(b.lastModified!);
    }
    // Cannot determine which is newer — keep existing
    return false;
  }

  /// Clear all data
  void clear() {
    _events = [];
    _lastFetch = null;
    _loadedStart = null;
    _loadedEnd = null;
    _error = null;
    notifyListeners();
  }

  /// Get events for a specific date
  List<ScheduleEvent> getEventsForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return _events.where((event) {
      final eventDate = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      return eventDate == targetDate;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Find next day with courses starting from a given date
  /// Returns null if no courses found in the next 14 days
  DateTime? findNextDayWithCourses(DateTime startDate) {
    final searchStart = DateTime(startDate.year, startDate.month, startDate.day);

    // Search for the next 14 days
    for (int i = 0; i < 14; i++) {
      final checkDate = searchStart.add(Duration(days: i));
      final eventsForDay = getEventsForDate(checkDate);

      if (eventsForDay.isNotEmpty) {
        return checkDate;
      }
    }

    return null; // No courses found in the next 14 days
  }

  /// Smart Day logic: Get the best date to display
  /// Returns today, or next Monday if weekend/no courses, or null if vacation
  DateTime? getSmartDisplayDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if today has courses
    if (getEventsForDate(today).isNotEmpty) {
      return today;
    }

    // If weekend or no courses today, find next Monday
    DateTime nextCheck = today;

    // If it's weekend (Saturday or Sunday), jump to next Monday
    if (now.weekday == DateTime.saturday) {
      nextCheck = today.add(const Duration(days: 2));
    } else if (now.weekday == DateTime.sunday) {
      nextCheck = today.add(const Duration(days: 1));
    }

    // Find next day with courses
    return findNextDayWithCourses(nextCheck);
  }
}
