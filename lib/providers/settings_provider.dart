import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../config/course_types.dart';
import '../config/event_style.dart';

/// Settings state provider
class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _viewMode = 'day'; // 'day' or 'week'
  Map<String, String> _courseColors = {};
  EventStyle _eventStyle = EventStyle.leftBar;
  String _showCurrentTimeIndicator = 'always'; // 'always' or 'current_day_only'

  ThemeMode get themeMode => _themeMode;
  String get viewMode => _viewMode;
  Map<String, String> get courseColors => _courseColors;
  EventStyle get eventStyle => _eventStyle;
  String get showCurrentTimeIndicator => _showCurrentTimeIndicator;

  /// Load settings from storage
  Future<void> loadSettings() async {
    _themeMode = await PreferencesService.getThemeMode();
    _viewMode = await PreferencesService.getViewMode();
    _courseColors = await PreferencesService.getCourseColors();
    try {
      _eventStyle = await PreferencesService.getEventStyle();
    } catch (e) {
      print('Error loading event style: $e');
      _eventStyle = EventStyle.leftBar; // Default value
    }
    _showCurrentTimeIndicator = await PreferencesService.getShowCurrentTimeIndicator();
    notifyListeners();
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await PreferencesService.setThemeMode(mode);
    notifyListeners();
  }

  /// Set view mode (day or week)
  Future<void> setViewMode(String mode) async {
    _viewMode = mode;
    await PreferencesService.setViewMode(mode);
    notifyListeners();
  }

  /// Set event display style
  Future<void> setEventStyle(EventStyle style) async {
    _eventStyle = style;
    await PreferencesService.setEventStyle(style);
    notifyListeners();
  }

  /// Set course color
  Future<void> setCourseColor(String type, String color) async {
    _courseColors[type] = color;
    await PreferencesService.setCourseColor(type, color);
    notifyListeners();
  }

  /// Reset course colors to default
  Future<void> resetCourseColors() async {
    await PreferencesService.resetCourseColors();
    _courseColors = await PreferencesService.getCourseColors();
    notifyListeners();
  }

  /// Set current time indicator display mode
  Future<void> setShowCurrentTimeIndicator(String mode) async {
    _showCurrentTimeIndicator = mode;
    await PreferencesService.setShowCurrentTimeIndicator(mode);
    notifyListeners();
  }

  /// Check if current time indicator should be shown for a given date
  bool shouldShowCurrentTimeIndicator(DateTime date) {
    if (_showCurrentTimeIndicator == 'always') {
      return true;
    }

    // Mode 'current_day_only': afficher seulement si c'est aujourd'hui
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Get color for a course type code
  Color getColorForCourseType(String typeCode) {
    try {
      return CourseTypes.getColor(typeCode, _courseColors);
    } catch (e) {
      print('Error getting color for type $typeCode: $e');
      return const Color(0xFF6B7280); // Default gray on error
    }
  }

  /// Get display label for a course type code
  String getLabelForCourseType(String typeCode) {
    return CourseTypes.getLabel(typeCode);
  }
}
