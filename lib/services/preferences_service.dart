import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/event_style.dart';

/// Service for managing user preferences
class PreferencesService {
  static const _storage = FlutterSecureStorage();

  // Keys
  static const _themeKey = 'theme_mode';
  static const _viewModeKey = 'view_mode';
  static const _courseColorsKey = 'course_colors';
  static const _eventStyleKey = 'event_style';
  static const _showCurrentTimeIndicatorKey = 'show_current_time_indicator';

  // Theme mode
  static Future<ThemeMode> getThemeMode() async {
    final value = await _storage.read(key: _themeKey);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
    }
    await _storage.write(key: _themeKey, value: value);
  }

  // View mode (day or week)
  static Future<String> getViewMode() async {
    final value = await _storage.read(key: _viewModeKey);
    return value ?? 'day'; // Default to day view
  }

  static Future<void> setViewMode(String mode) async {
    await _storage.write(key: _viewModeKey, value: mode);
  }

  // Course colors
  static Future<Map<String, String>> getCourseColors() async {
    // Default colors based on requirements (using course type codes)
    const defaultColors = {
      'COU': '#F59E0B', // Cours magistraux (Orange)
      'TD': '#3B82F6', // Travaux dirigés (Blue)
      'TP': '#3BB77E', // Travaux pratiques (Green)
      'EXA': '#EF4444', // Examen (Red)
      '74': '#8B5CF6', // Mini-projet (Purple)
      'RDV': '#8B9467', // Rendez-vous (Olive)
      'MEM': '#60A5FA', // Mémo (Light blue)
    };

    try {
      final value = await _storage.read(key: _courseColorsKey);
      if (value == null || value.isEmpty) {
        return Map<String, String>.from(defaultColors);
      }

      // Parse stored colors (format: "type1:color1,type2:color2")
      final colors = Map<String, String>.from(defaultColors);
      final pairs = value.split(',');
      for (final pair in pairs) {
        if (pair.isEmpty) continue;
        final parts = pair.split(':');
        if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
          colors[parts[0]] = parts[1];
        }
      }
      return colors;
    } catch (e) {
      print('Error loading course colors: $e');
      return Map<String, String>.from(defaultColors);
    }
  }

  static Future<void> setCourseColor(String type, String color) async {
    final colors = await getCourseColors();
    colors[type] = color;

    // Convert to string format
    final value = colors.entries.map((e) => '${e.key}:${e.value}').join(',');
    await _storage.write(key: _courseColorsKey, value: value);
  }

  static Future<void> resetCourseColors() async {
    await _storage.delete(key: _courseColorsKey);
  }

  // Event display style
  static Future<EventStyle> getEventStyle() async {
    try {
      final value = await _storage.read(key: _eventStyleKey);
      if (value == null) {
        return EventStyle.leftBar;
      }
      switch (value) {
        case 'leftBar':
          return EventStyle.leftBar;
        case 'filled':
          return EventStyle.filled;
        case 'outlined':
          return EventStyle.outlined;
        case 'filledLight':
          return EventStyle.filledLight;
        default:
          return EventStyle.leftBar;
      }
    } catch (e) {
      print('Error reading event style: $e');
      return EventStyle.leftBar;
    }
  }

  static Future<void> setEventStyle(EventStyle style) async {
    String value;
    switch (style) {
      case EventStyle.leftBar:
        value = 'leftBar';
        break;
      case EventStyle.filled:
        value = 'filled';
        break;
      case EventStyle.outlined:
        value = 'outlined';
        break;
      case EventStyle.filledLight:
        value = 'filledLight';
        break;
    }
    await _storage.write(key: _eventStyleKey, value: value);
  }

  // Current time indicator display option
  // 'always' = afficher sur tous les jours
  // 'current_day_only' = afficher seulement le jour actuel (lundi-vendredi)
  static Future<String> getShowCurrentTimeIndicator() async {
    final value = await _storage.read(key: _showCurrentTimeIndicatorKey);
    return value ?? 'always'; // Par défaut, afficher toujours
  }

  static Future<void> setShowCurrentTimeIndicator(String mode) async {
    await _storage.write(key: _showCurrentTimeIndicatorKey, value: mode);
  }
}
