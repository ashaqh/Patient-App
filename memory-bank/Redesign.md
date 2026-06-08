# Patient Companion UI Redesign Specification

## Objective
Redesign the entire application UI to achieve a modern premium health-tech appearance inspired by the supplied reference image.

### Important Constraints
DO NOT CHANGE:
- Existing features
- Existing screens
- Existing navigation structure
- Existing providers
- Existing repositories
- Existing database schema
- Existing business logic
- Existing reminder system
- Existing encryption/security systems

ONLY CHANGE:
- Visual design
- Layout composition
- Component styling
- Color system
- Typography
- Animations
- Visual hierarchy

---

# Design Language

## Style
Combine:
- Glassmorphism
- Neo-healthcare aesthetics
- Soft gradients
- Premium mobile fintech quality
- Modern fitness/health dashboard appearance

Visual keywords:
- Frosted glass
- Blur backgrounds
- Floating cards
- Depth
- Soft shadows
- Gradient illumination
- Rounded geometry

---

# Color System

## Primary
```dart
Primary Blue = #3B82F6
Primary Teal = #14B8A6
```

## Secondary
```dart
Deep Navy = #0F172A
Dark Surface = #111827
```

## Accent
```dart
Success = #22C55E
Warning = #F59E0B
Danger = #EF4444
Info = #60A5FA
```

## Background Gradient
```dart
LinearGradient(
  begin: topLeft,
  end: bottomRight,
  colors: [
    Color(0xFF0F172A),
    Color(0xFF1E3A8A),
    Color(0xFF0F172A)
  ]
)
```

---

# Typography

Use GoogleFonts.inter()

### Display
- 32
- Weight.w700

### Heading
- 24
- Weight.w600

### Section Title
- 18
- Weight.w600

### Body
- 15
- Weight.w400

### Caption
- 12
- Weight.w400

---

# Global UI Components

## Glass Card
Replace all existing cards.

```dart
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(28),
    color: Colors.white.withOpacity(.08),
    border: Border.all(
      color: Colors.white.withOpacity(.15)
    ),
    boxShadow: [
      BoxShadow(
        blurRadius: 30,
        color: Colors.black26
      )
    ]
  )
)
```

Use BackdropFilter blur.

## Floating Action Button
- Circular
- Gradient fill
- White icon
- Size: 72x72

## App Bars
Replace traditional app bars with:
- Greeting
- Current Date
- User Avatar

---


# Animations

Use flutter_animate

### Page Entry
Fade + Slide (300ms)

### Cards
Scale 0.95 → 1.0

### FAB
Floating pulse

### Navigation
Smooth icon transitions

---

# Accessibility

- Minimum touch target 48dp
- Large readable fonts
- High contrast text
- Elderly-friendly hierarchy

---

# Implementation Notes

Create reusable widgets:
- GlassCard
- GlassButton
- GradientFAB
- HealthStatCard
- MedicineGlassCard
- SectionHeader
- GlassSearchBar

Centralize styling in app_theme.dart

Dependencies:
```yaml
glassmorphism:
flutter_animate:
google_fonts:
```

Preserve all existing Riverpod providers, SQLite schema, repositories, notifications, security services, and business logic.

---

# Expected Outcome

A premium healthcare application featuring:
- Dark blue gradient backgrounds
- Glassmorphism cards
- Floating navigation
- Modern progress widgets
- Elegant animations
- High-end wellness application aesthetics

While retaining 100% of existing functionality.
