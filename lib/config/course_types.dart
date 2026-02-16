import 'package:flutter/material.dart';

/// Course types configuration with colors and labels
class CourseTypes {
  // Course type codes mapping
  static const Map<String, String> typeLabels = {
    'COU': 'Cours magistral',
    'TD': 'Travaux dirigés',
    'TP': 'Travaux pratiques',
    'EXA': 'Examen',
    '74': 'Mini-projet',
    '77': 'Conférence',
    'RDV': 'Rendez-vous',
    'MEM': 'Mémo',
  };

  // Default colors (from requirements)
  static const Map<String, String> defaultColors = {
    'COU': '#F59E0B', // Cours magistraux (Orange)
    'TD': '#3B82F6', // Travaux dirigés (Blue)
    'TP': '#3BB77E', // Travaux pratiques (Green)
    'EXA': '#EF4444', // Examen (Red)
    '74': '#8B5CF6', // Mini-projet (Purple)
    '77': '#14B8A6', // Conférence (Teal)
    'RDV': '#8B9467', // Rendez-vous (Olive)
    'MEM': '#60A5FA', // Mémo (Light blue)
  };

  /// Get display label for a course type code
  static String getLabel(String code) {
    return typeLabels[code] ?? code;
  }

  /// Convert hex color string to Color object
  static Color hexToColor(String hexString) {
    try {
      final hex = hexString.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
      return const Color(0xFF6B7280); // Default gray
    } catch (e) {
      return const Color(0xFF6B7280); // Default gray on error
    }
  }

  /// Get color for a course type code
  static Color getColor(String code, Map<String, String>? customColors) {
    final colorMap = customColors ?? defaultColors;
    final colorHex = colorMap[code] ?? defaultColors[code] ?? '#6B7280';
    return hexToColor(colorHex);
  }

  /// Get all course types
  static List<String> getAllTypes() {
    return typeLabels.keys.toList();
  }
}
