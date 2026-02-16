/// Event display styles
enum EventStyle {
  leftBar,      // Barre de couleur à gauche (défaut)
  filled,       // Case entière de couleur
  outlined,     // Contour de couleur seulement
  filledLight,  // Contour + fond transparent (comme dans les détails)
}

class EventStyleConfig {
  static const Map<EventStyle, String> labels = {
    EventStyle.leftBar: 'Barre à gauche',
    EventStyle.filled: 'Fond coloré',
    EventStyle.outlined: 'Contour seulement',
    EventStyle.filledLight: 'Contour + fond transparent',
  };

  static String getLabel(EventStyle style) {
    return labels[style] ?? labels[EventStyle.leftBar]!;
  }
}
