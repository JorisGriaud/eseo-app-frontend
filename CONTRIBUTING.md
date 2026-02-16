# 🤝 Guide de contribution

Merci de votre intérêt pour contribuer à EDT App ! Ce guide vous aidera à démarrer.

## 📋 Table des matières

- [Code de conduite](#code-de-conduite)
- [Comment contribuer](#comment-contribuer)
- [Standards de code](#standards-de-code)
- [Process de Pull Request](#process-de-pull-request)
- [Reporting de bugs](#reporting-de-bugs)
- [Suggestions de fonctionnalités](#suggestions-de-fonctionnalités)

## 📜 Code de conduite

En participant à ce projet, vous acceptez de respecter notre code de conduite :

- Soyez respectueux et inclusif
- Acceptez les critiques constructives
- Concentrez-vous sur ce qui est meilleur pour la communauté
- Faites preuve d'empathie envers les autres membres

## 🚀 Comment contribuer

### 1. Fork le projet

Cliquez sur le bouton "Fork" en haut à droite de la page du repository.

### 2. Clonez votre fork

```bash
git clone https://github.com/votre-username/edt_app_flutter.git
cd edt_app_flutter
```

### 3. Créez une branche

```bash
git checkout -b feature/ma-nouvelle-fonctionnalite
```

Nommez votre branche selon la convention :
- `feature/` pour les nouvelles fonctionnalités
- `fix/` pour les corrections de bugs
- `docs/` pour les modifications de documentation
- `refactor/` pour les refactorisations de code

### 4. Installez les dépendances

```bash
flutter pub get
```

### 5. Faites vos modifications

- Écrivez du code propre et bien documenté
- Suivez les standards de code Flutter/Dart
- Ajoutez des tests si nécessaire
- Mettez à jour la documentation

### 6. Testez vos modifications

```bash
# Analyse du code
flutter analyze

# Formatage
flutter format lib/ --set-exit-if-changed

# Tests (si disponibles)
flutter test
```

### 7. Committez vos changements

```bash
git add .
git commit -m "feat: ajout de la fonctionnalité X"
```

Utilisez des messages de commit conventionnels :
- `feat:` nouvelle fonctionnalité
- `fix:` correction de bug
- `docs:` documentation
- `style:` formatage, points-virgules manquants, etc.
- `refactor:` refactorisation de code
- `test:` ajout de tests
- `chore:` tâches de maintenance

### 8. Poussez vers votre fork

```bash
git push origin feature/ma-nouvelle-fonctionnalite
```

### 9. Créez une Pull Request

Allez sur le repository original et cliquez sur "New Pull Request".

## 📝 Standards de code

### Dart/Flutter

- Suivez le [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Utilisez `flutter format` avant de committer
- Maximum 80 caractères par ligne (recommandé)
- Préférez `final` à `var` quand c'est possible
- Utilisez des noms de variables descriptifs

### Structure des fichiers

```dart
// 1. Imports Flutter/Dart
import 'package:flutter/material.dart';

// 2. Imports de packages tiers
import 'package:provider/provider.dart';

// 3. Imports locaux
import '../models/schedule_event.dart';
import '../services/api_service.dart';

// 4. Code...
```

### Documentation

- Ajoutez des commentaires `///` pour les classes et méthodes publiques
- Expliquez le "pourquoi", pas le "quoi"
- Utilisez des exemples dans la documentation si nécessaire

```dart
/// Calcule la position verticale d'un événement sur la timeline.
///
/// La position est calculée en fonction de l'heure de début
/// et de la hauteur d'une heure définie par [hourHeight].
///
/// Returns la position en pixels depuis le haut de la timeline.
double _calculateEventTop(DateTime time) {
  // ...
}
```

### State Management

- Utilisez Provider pour la gestion d'état
- Évitez `setState()` dans les widgets complexes
- Préférez `Consumer` à `Provider.of` quand possible

### Widgets

- Privilégiez les widgets stateless quand c'est possible
- Extrayez les widgets complexes en widgets séparés
- Utilisez `const` constructors quand possible

## 🔍 Process de Pull Request

### Checklist avant de soumettre

- [ ] Le code compile sans erreurs ni warnings
- [ ] `flutter analyze` ne retourne aucune erreur
- [ ] Le code est formaté avec `flutter format`
- [ ] Les tests passent (si applicable)
- [ ] La documentation est à jour
- [ ] Le README est mis à jour si nécessaire
- [ ] Pas de fichiers sensibles (tokens, clés API, etc.)

### Description de la PR

Incluez dans votre PR :

1. **Description** : Que fait cette PR ?
2. **Motivation** : Pourquoi ce changement est nécessaire ?
3. **Tests** : Comment avez-vous testé ?
4. **Screenshots** : Si changements visuels
5. **Breaking changes** : Y a-t-il des changements incompatibles ?

### Template de PR

```markdown
## Description
Brève description des changements

## Type de changement
- [ ] Bug fix (changement non-breaking qui corrige un problème)
- [ ] Nouvelle fonctionnalité (changement non-breaking qui ajoute une fonctionnalité)
- [ ] Breaking change (correction ou fonctionnalité qui causerait un dysfonctionnement des fonctionnalités existantes)
- [ ] Documentation

## Comment cela a-t-il été testé ?
Décrivez les tests effectués

## Screenshots (si applicable)
Ajoutez des captures d'écran

## Checklist
- [ ] Mon code suit les standards du projet
- [ ] J'ai effectué une auto-revue de mon code
- [ ] J'ai commenté mon code, notamment dans les zones difficiles
- [ ] J'ai mis à jour la documentation
- [ ] Mes changements ne génèrent pas de nouveaux warnings
- [ ] J'ai ajouté des tests qui prouvent que ma correction est efficace ou que ma fonctionnalité fonctionne
```

## 🐛 Reporting de bugs

### Avant de reporter un bug

1. Vérifiez que le bug n'a pas déjà été reporté
2. Vérifiez que vous utilisez la dernière version
3. Essayez de reproduire le bug de manière consistante

### Template de bug report

```markdown
**Description du bug**
Une description claire et concise du bug.

**Comment reproduire**
Étapes pour reproduire le comportement :
1. Aller à '...'
2. Cliquer sur '...'
3. Scroller jusqu'à '...'
4. Voir l'erreur

**Comportement attendu**
Description claire de ce qui devrait se passer.

**Screenshots**
Si applicable, ajoutez des captures d'écran.

**Environnement**
 - Device: [e.g. iPhone 12, Samsung Galaxy S21]
 - OS: [e.g. iOS 15.0, Android 12]
 - App version: [e.g. 1.0.0]
 - Flutter version: [e.g. 3.10.0]

**Logs/Stack trace**
```
Collez les logs pertinents ici
```

**Contexte additionnel**
Tout autre contexte pertinent.
```

## 💡 Suggestions de fonctionnalités

### Template de feature request

```markdown
**La fonctionnalité est-elle liée à un problème ?**
Une description claire et concise du problème. Ex: Je suis toujours frustré quand [...]

**Décrivez la solution que vous aimeriez**
Une description claire et concise de ce que vous voulez qu'il se passe.

**Décrivez les alternatives que vous avez considérées**
Une description claire et concise des solutions ou fonctionnalités alternatives que vous avez considérées.

**Mockups/Screenshots**
Si applicable, ajoutez des mockups ou captures d'écran.

**Contexte additionnel**
Tout autre contexte ou captures d'écran à propos de la feature request.
```

## 📚 Ressources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Widget Catalog](https://docs.flutter.dev/development/ui/widgets)
- [Provider Documentation](https://pub.dev/packages/provider)

## 🎯 Domaines où contribuer

Voici quelques domaines où vos contributions seraient particulièrement appréciées :

- 🐛 Corrections de bugs
- ✨ Nouvelles fonctionnalités (voir Roadmap dans README)
- 📝 Amélioration de la documentation
- 🎨 Améliorations UI/UX
- ⚡ Optimisations de performance
- 🧪 Ajout de tests
- 🌍 Traductions (internationalisation)
- ♿ Améliorations d'accessibilité

## ❓ Questions ?

Si vous avez des questions, n'hésitez pas à :

1. Ouvrir une [Discussion](../../discussions)
2. Consulter les [Issues](../../issues) existantes
3. Contacter les mainteneurs

---

**Merci de contribuer à EDT App ! 🎉**
