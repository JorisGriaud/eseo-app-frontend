import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../config/course_types.dart';
import '../config/event_style.dart';
import 'login_screen.dart';

/// Settings tab - theme, colors, actions
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: ValueKey('settings_${theme.brightness.name}'),
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        children: [
          // Theme section
          _buildSectionHeader(context, 'Apparence'),
          _buildThemeSelector(context),

          Divider(
            height: 32,
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF5A5F64) // Dark: border
                : const Color(0xFFD1D5DB), // Light: border
          ),

          // Course colors section
          _buildSectionHeader(context, 'Couleurs des cours'),
          _buildCourseColorsList(context),

          _buildResetColorsButton(context),

          Divider(
            height: 32,
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF5A5F64) // Dark: border
                : const Color(0xFFD1D5DB), // Light: border
          ),

          // Event style section
          _buildSectionHeader(context, 'Style d\'affichage'),
          _buildEventStyleSelector(context),

          Divider(
            height: 32,
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF5A5F64) // Dark: border
                : const Color(0xFFD1D5DB), // Light: border
          ),

          // Actions section
          _buildSectionHeader(context, 'Actions'),
          _buildRefreshButton(context),

          Divider(
            height: 32,
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF5A5F64) // Dark: border
                : const Color(0xFFD1D5DB), // Light: border
          ),

          // Current time indicator section
          _buildSectionHeader(context, 'Indicateur d\'heure'),
          _buildCurrentTimeIndicatorOption(context),

          Divider(
            height: 32,
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF5A5F64) // Dark: border
                : const Color(0xFFD1D5DB), // Light: border
          ),

          // Logout section
          _buildLogoutButton(context),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              inherit: true,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final isAutomatic = settings.themeMode == ThemeMode.system;
        final isDark = settings.themeMode == ThemeMode.dark;

        return Column(
          children: [
            // Checkbox pour le mode automatique
            CheckboxListTile(
              key: const ValueKey('theme_automatic'),
              title: const Text('Automatique'),
              subtitle: const Text('Suit le thème de votre appareil'),
              value: isAutomatic,
              onChanged: (value) {
                if (value == true) {
                  settings.setThemeMode(ThemeMode.system);
                } else {
                  // Si on désactive l'automatique, on passe au mode actuel
                  final brightness = Theme.of(context).brightness;
                  settings.setThemeMode(
                    brightness == Brightness.dark
                        ? ThemeMode.dark
                        : ThemeMode.light
                  );
                }
              },
            ),
            // Toggle Dark/Light (désactivé si automatique)
            SwitchListTile(
              key: const ValueKey('theme_toggle'),
              title: Text(isDark ? 'Thème sombre' : 'Thème clair'),
              subtitle: Text(isDark ? 'Mode sombre activé' : 'Mode clair activé'),
              value: isDark,
              onChanged: isAutomatic ? null : (value) {
                settings.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
              },
              secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRefreshButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: OutlinedButton.icon(
        onPressed: () async {
          final scheduleProvider =
              Provider.of<ScheduleProvider>(context, listen: false);

          // Show loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Actualisation de l\'emploi du temps...'),
              duration: Duration(seconds: 1),
            ),
          );

          await scheduleProvider.refreshSchedule();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Emploi du temps mis à jour'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Actualiser l\'emploi du temps'),
      ),
    );
  }

  Widget _buildCourseColorsList(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        // Use all available course types from CourseTypes
        final courseTypes = CourseTypes.typeLabels.keys.toList();

        return Column(
          children: courseTypes.map((typeCode) {
            final color = settings.getColorForCourseType(typeCode);
            final label = settings.getLabelForCourseType(typeCode);

            return ListTile(
              key: ValueKey('course_color_$typeCode'),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              title: Text(label),
              subtitle: Text(
                typeCode,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      inherit: true,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _showColorPicker(context, typeCode, label, color),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildResetColorsButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Réinitialiser les couleurs'),
              content: const Text(
                'Voulez-vous restaurer les couleurs par défaut ?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Réinitialiser'),
                ),
              ],
            ),
          );

          if (confirmed == true && context.mounted) {
            await Provider.of<SettingsProvider>(context, listen: false)
                .resetCourseColors();
          }
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Réinitialiser les couleurs'),
      ),
    );
  }

  Widget _buildEventStyleSelector(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final theme = Theme.of(context);
        final sampleColor = theme.colorScheme.primary;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choisissez comment afficher les cours',
                style: theme.textTheme.bodyMedium?.copyWith(
                  inherit: true,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              // Grid de 4 styles
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: EventStyle.values.map((style) {
                  final isSelected = settings.eventStyle == style;
                  return _buildStyleOption(
                    context,
                    style,
                    isSelected,
                    sampleColor,
                    () => settings.setEventStyle(style),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStyleOption(
    BuildContext context,
    EventStyle style,
    bool isSelected,
    Color sampleColor,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor,
            width: isSelected ? 3 : 1,
          ),
          color: theme.colorScheme.surface,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aperçu du style
            Container(
              height: 50,
              decoration: _getStyleDecoration(style, sampleColor, theme),
              child: Center(
                child: Text(
                  'Cours',
                  style: theme.textTheme.labelSmall?.copyWith(
                    inherit: true,
                    color: _getStyleTextColor(style, sampleColor, theme),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Label
            Text(
              EventStyleConfig.getLabel(style),
              style: theme.textTheme.labelSmall?.copyWith(
                inherit: true,
                color: theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _getStyleDecoration(EventStyle style, Color color, ThemeData theme) {
    switch (style) {
      case EventStyle.leftBar:
        return BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(color: color, width: 4),
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

  Color _getStyleTextColor(EventStyle style, Color color, ThemeData theme) {
    switch (style) {
      case EventStyle.filled:
        return Colors.white;
      default:
        return theme.colorScheme.onSurface;
    }
  }

  void _showColorPicker(
      BuildContext context, String typeCode, String label, Color currentColor) {
    final TextEditingController hexController = TextEditingController(
      text: currentColor.value.toRadixString(16).substring(2).toUpperCase(),
    );
    Color previewColor = currentColor;

    final colors = [
      CourseTypes.hexToColor('#F59E0B'), // COU - Amber
      CourseTypes.hexToColor('#3B82F6'), // TD - Blue
      CourseTypes.hexToColor('#3BB77E'), // TP - Green
      CourseTypes.hexToColor('#EF4444'), // EXA - Red
      CourseTypes.hexToColor('#8B5CF6'), // 74 - Purple
      CourseTypes.hexToColor('#8B9467'), // RDV - Olive
      CourseTypes.hexToColor('#60A5FA'), // MEM - Light blue
      CourseTypes.hexToColor('#14B8A6'), // 77 - Teal
      const Color(0xFFD97706), // Orange
      const Color(0xFF059669), // Dark green
      const Color(0xFF7C3AED), // Violet
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF6B7280), // Gray
      const Color(0xFFEC4899), // Pink
      const Color(0xFF10B981), // Emerald
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Couleur - $label'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Champ de saisie hexadécimal
                Text(
                  'Code hexadécimal',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        inherit: true,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hexController,
                        decoration: InputDecoration(
                          hintText: 'RRGGBB',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.tag),
                        ),
                        onChanged: (value) {
                          setState(() {
                            try {
                              // Essayer de parser la couleur (sans le #)
                              String hex = value.toUpperCase();
                              if (hex.length == 6) {
                                previewColor = CourseTypes.hexToColor('#$hex');
                              }
                            } catch (e) {
                              // Ignorer les erreurs de parsing
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Prévisualisation
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: previewColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Couleurs prédéfinies
                Text(
                  'Couleurs suggérées',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        inherit: true,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          previewColor = color;
                          hexController.text =
                              color.value.toRadixString(16).substring(2).toUpperCase();
                        });
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color.value == previewColor.value
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                            width: color.value == previewColor.value ? 3 : 1,
                          ),
                        ),
                        child: color.value == previewColor.value
                            ? Icon(Icons.check,
                                color: Theme.of(context).colorScheme.primary)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                // Valider et appliquer la couleur
                String hex = hexController.text.toUpperCase();
                if (hex.length == 6) {
                  try {
                    // Vérifier que c'est un hex valide
                    int.parse(hex, radix: 16);
                    Provider.of<SettingsProvider>(context, listen: false)
                        .setCourseColor(typeCode, '#$hex');
                    Navigator.pop(context);
                  } catch (e) {
                    // Afficher un message d'erreur
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code hexadécimal invalide'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le code doit contenir 6 caractères'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Appliquer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _handleLogout(context),
          icon: const Icon(Icons.logout),
          label: const Text('Se déconnecter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Afficher une confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);

      // Nettoyer les données
      scheduleProvider.clear();
      await authProvider.logout();

      if (!context.mounted) return;

      // Rediriger vers l'écran de connexion
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildCurrentTimeIndicatorOption(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          children: [
            RadioListTile<String>(
              title: const Text('Afficher sur tous les jours'),
              subtitle: const Text('L\'indicateur d\'heure est toujours visible'),
              value: 'always',
              groupValue: settings.showCurrentTimeIndicator,
              onChanged: (value) {
                if (value != null) {
                  settings.setShowCurrentTimeIndicator(value);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Afficher uniquement aujourd\'hui'),
              subtitle: const Text('L\'indicateur n\'apparaît que le jour actuel'),
              value: 'current_day_only',
              groupValue: settings.showCurrentTimeIndicator,
              onChanged: (value) {
                if (value != null) {
                  settings.setShowCurrentTimeIndicator(value);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
