/// Schedule event (cours) model
class ScheduleEvent {
  final String id;
  final String title; // Libelle
  final String type; // Type de cours
  final String location; // Emplacement
  final String professor; // Professeur
  final DateTime startTime;
  final DateTime endTime;
  final String? description;
  final DateTime? lastModified; // Date de dernière modification (optionnel, fourni par le backend)

  ScheduleEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
    required this.professor,
    required this.startTime,
    required this.endTime,
    this.description,
    this.lastModified,
  });

  /// Create ScheduleEvent from JSON response from ESEO API
  /// Supports both formats: old (Libelle, Type) and new (titre, categorie_code)
  factory ScheduleEvent.fromJson(Map<String, dynamic> json) {
    // Support both formats
    String courseType = json['Type'] ??
        json['Categorie'] ??
        json['categorie'] ??
        json['categorie_code'] ??
        'COU';

    return ScheduleEvent(
      id: json['Id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['Libelle'] ?? json['titre'] ?? 'Sans titre',
      type: courseType,
      location: json['Emplacement'] ?? json['salle'] ?? '',
      professor: json['professeur'] ?? json['Professeur'] ?? json['prof'] ?? json['enseignant'] ?? '',
      startTime: json['DateDebut'] != null
          ? DateTime.parse(json['DateDebut']).toLocal()
          : (json['debut'] != null
              ? DateTime.parse(json['debut']).toLocal()
              : DateTime.now()),
      endTime: json['DateFin'] != null
          ? DateTime.parse(json['DateFin']).toLocal()
          : (json['fin'] != null
              ? DateTime.parse(json['fin']).toLocal()
              : DateTime.now().add(const Duration(hours: 2))),
      description: json['Description'] ?? json['description'],
      lastModified: (json['created_at'] ?? json['lastModified'] ?? json['updatedAt'] ?? json['last_modified']) != null
          ? DateTime.tryParse(json['created_at'] ?? json['lastModified'] ?? json['updatedAt'] ?? json['last_modified'])?.toLocal()
          : null,
    );
  }

  /// Get formatted time range (e.g., "08:00 - 10:00")
  String get timeRange {
    final start = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  /// Get duration in minutes
  int get durationMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  /// Check if event is today
  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }

  /// Check if event is currently happening
  bool get isHappening {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }
}
