# DESIGN.md — FamilyGuard

Guide de style visuel. Claude Code doit lire ce fichier avant de créer ou modifier n'importe quel écran ou widget.
Exemple d'inspiration docs/examples/core_widgets.dart

---

## Philosophie visuelle

FamilyGuard adopte un style inspiré d'iOS 26 : **liquid glass**, surfaces translucides avec flou d'arrière-plan, coins très arrondis, fond sombre dégradé violet. L'app doit donner une impression de profondeur et de légèreté — pas de surfaces opaques et plates.

Mots-clés : glassmorphism · violet profond · dark mode · doux · familial · moderne

---

## Couleurs

```dart
// lib/core/theme/app_colors.dart

class AppColors {
  // Violet — couleur principale
  static const primary        = Color(0xFF7C3AED);
  static const primaryLight   = Color(0xFFA855F7);
  static const primaryDark    = Color(0xFF6D28D9);
  static const primarySurface = Color(0x407C3AED); // 25% opacity

  // Fond de l'écran — dégradé sombre violet
  static const bgGradientTop    = Color(0xFF0D0020);
  static const bgGradientMid    = Color(0xFF1A0040);
  static const bgGradientBottom = Color(0xFF0D0020);

  // Glass surfaces
  static const glassSurface       = Color(0x14FFFFFF); // 8% blanc
  static const glassBorder        = Color(0x26FFFFFF); // 15% blanc
  static const glassPurpleSurface = Color(0x407C3AED); // violet teinté
  static const glassPurpleBorder  = Color(0x4DA87AFD); // violet clair

  // Texte
  static const textPrimary    = Color(0xFFFFFFFF);
  static const textSecondary  = Color(0x80FFFFFF); // 50%
  static const textTertiary   = Color(0x40FFFFFF); // 25%
  static const textLabel      = Color(0x73FFFFFF); // 45% — labels uppercase

  // Badges status
  static const badgeWaiting  = Color(0x33FCD34D); // fond
  static const badgeWaitingText  = Color(0xFFFCD34D);
  static const badgeAccepted = Color(0x3334D399);
  static const badgeAcceptedText = Color(0xFF6EE7B7);
  static const badgeNew      = Color(0x40A78BFA);
  static const badgeNewText  = Color(0xFFC4B5FD);

  // Avatars (fond par initiales)
  static const avatarPurple = Color(0x668B5CF6);
  static const avatarPink   = Color(0x4DEC4899);
  static const avatarTeal   = Color(0x4D14B8A6);
}
```

---

## Typographie

```dart
// lib/core/theme/app_text_styles.dart
// Police : DM Sans (google_fonts)

class AppTextStyles {
  static TextStyle greeting = GoogleFonts.dmSans(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, letterSpacing: 0.2,
  );

  static TextStyle screenTitle = GoogleFonts.dmSans(
    fontSize: 26, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, letterSpacing: -0.5,
  );

  static TextStyle sectionLabel = GoogleFonts.dmSans(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.textLabel, letterSpacing: 0.8,
  );

  static TextStyle cardTitle = GoogleFonts.dmSans(
    fontSize: 14, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle cardSubtitle = GoogleFonts.dmSans(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle buttonPrimary = GoogleFonts.dmSans(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle tabLabel = GoogleFonts.dmSans(
    fontSize: 10, fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  static TextStyle badge = GoogleFonts.dmSans(
    fontSize: 11, fontWeight: FontWeight.w600,
  );
}
```

---

## Fond d'écran

Chaque écran a un fond dégradé violet sombre avec des "orbs" floutées pour simuler la profondeur. Utiliser `AppBackground` comme widget racine de chaque écran.

```dart
// Voir lib/core/theme/app_background.dart
// Dégradé : bgGradientTop → bgGradientMid → bgGradientBottom
// + 3 cercles floutés (violet, violet clair, violet foncé)
// positionnés en haut-gauche, droite-milieu, bas-gauche
```

---

## Composants de base

Tous les widgets de base sont dans `lib/core/widgets/`. **Ne jamais recréer ces widgets inline — toujours les importer.**

### `GlassCard`
Surface translucide principale. Paramètre `purpleTint: true` pour la variante violet.

### `GlassButton`
Bouton CTA principal avec dégradé violet. Utilisé pour les actions primaires ("Nouvelle demande", "Confirmer", etc.)

### `AvatarInitials`
Avatar rond avec initiales, fond coloré semi-transparent.

### `StatusBadge`
Badge de statut coloré (waiting / accepted / declined / new).

### `ChildPill`
Card enfant avec emoji, prénom, âge. Version "+" pour ajouter.

### `GlassTabBar`
Bottom navigation bar glassmorphique avec 4 onglets.

### `SectionLabel`
Label de section en uppercase, texte grisé, style iOS.

---

## Règles impératives

1. **Fond** : toujours `AppBackground` comme widget racine du `Scaffold`. Jamais de `backgroundColor` opaque sur le `Scaffold`.

2. **Surfaces** : toujours `GlassCard` ou `ClipRRect` + `BackdropFilter` + `Container` semi-transparent. Jamais de `Card()` Flutter par défaut.

3. **Border radius** : minimum `24.0` pour les cards, `18.0` pour les pills, `50.0` pour les avatars et boutons ronds.

4. **Bordures** : `Border.all(color: AppColors.glassBorder, width: 0.5)` sur tous les glass containers.

5. **Blur** : `BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20))` sur tous les glass containers.

6. **Texte sur fond coloré** : toujours utiliser les couleurs de `AppColors`, jamais `Colors.white` ou `Colors.black` directement.

7. **Spacing** : padding intérieur des cards = `EdgeInsets.all(16)`. Margin entre cards = `12px`. Padding latéral des écrans = `16px`.

8. **Icônes** : utiliser `Lucide Icons` (`lucide_icons` package). Taille standard = `20px` inline, `24px` décoratif.

9. **Animations** : utiliser `flutter_animate` pour les apparitions d'écrans (`fadeIn`, `slideY`). Durée standard = `300ms`, courbe = `Curves.easeOut`.

10. **Dark mode uniquement** : l'app est exclusivement dark. Pas de `MediaQuery.of(context).platformBrightness` — forcer `ThemeMode.dark`.

---

## ThemeData

```dart
// lib/core/theme/app_theme.dart

ThemeData appTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.primary,
      surface: Colors.transparent,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    fontFamily: GoogleFonts.dmSans().fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}
```

---

## Exemple d'écran type

```dart
class ExampleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bonjour, Franck 👋', style: AppTextStyles.greeting),
                    SizedBox(height: 2),
                    Text('FamilyGuard', style: AppTextStyles.screenTitle),
                  ],
                ),
              ),
              // Contenu
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    GlassButton(
                      label: 'Nouvelle demande',
                      subtitle: 'Trouver une garde rapidement',
                      icon: LucideIcons.plus,
                      onTap: () {},
                    ),
                    SizedBox(height: 12),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionLabel('Mes enfants'),
                          SizedBox(height: 10),
                          // contenu...
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## À ne jamais faire

```dart
// ❌ Card Flutter par défaut
Card(child: ...)

// ❌ Couleur opaque sur le scaffold
Scaffold(backgroundColor: Colors.black, ...)

// ❌ Border radius trop petit
BorderRadius.circular(8)

// ❌ Texte blanc hardcodé
Text('titre', style: TextStyle(color: Colors.white))

// ❌ Pas de blur sur une glass card
Container(color: Color(0x14FFFFFF), ...)

// ❌ Bouton Material par défaut
ElevatedButton(...)
```

---

*Lire ce fichier avant tout travail sur l'UI. En cas de doute sur un style, préférer la version la plus "liquid glass" et la plus arrondie.*
