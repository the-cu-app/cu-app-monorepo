# Zero Material Omni Design System - Section 1033 Compliant Routes Plan

## ⚠️ CRITICAL: ZERO MATERIAL DESIGN
This app uses **CU Design System Omni** - a zero-material, custom design system.
**DO NOT** use any Material Design components, widgets, or patterns.

---

## Design System: CU Design System Omni

### Package Location
```yaml
cu_design_system_omni:
  path: ../../../clean rust/supafi_ai 2/packages/cu_design_system_omni
```

### Core Components Available
- `CUTheme` - Theme system
- `CUThemeData` - Theme data structure
- `CUColorScheme` - Color scheme
- `CUOutlinedCard` - Card component
- `CUApp` - App wrapper
- Custom typography system (Geist font)

---

## ✅ Completed Updates

### Home Dashboard
**Route:** `/home` → `SimpleDashboardScreen`
- ✅ Removed time/weather banner
- ✅ Added Credit Union federated avatar (circular "CU" badge)
- ✅ Rounded Transfer and Accounts buttons (borderRadius: 100)
- ✅ Disabled Transfer and Accounts buttons (opacity: 0.4)
- ✅ Made Plaid account cards tappable for navigation to details
- ✅ All text uses Geist font family
- ✅ Using CU Omni design system components
- **File:** `lib/screens/simple_dashboard_screen.dart`

### Accessibility Settings
**Route:** `/accessibility` → `AccessibilitySettingsScreen`
- ✅ Header uses large Geist font (32px, bold)
- ✅ Subtitle uses Geist (16px, grey)
- ✅ Back button with Geist font
- ✅ All cards use CUOutlinedCard (Omni component)
- ✅ Custom switch toggles (zero material)
- ✅ Custom radio buttons (zero material)
- **File:** `lib/screens/accessibility_settings_screen.dart`

### Settings Hub
**Route:** `/settings` (Tab 3 in HomeScreen)
- ✅ Header uses large Geist font (32px, bold)
- ✅ Section 1033 banner with federal data rights notice
- ✅ All text uses Geist font family
- ✅ Using CU Omni design system
- **File:** `lib/screens/settings_screen.dart`

---

## 🔄 Routes Requiring Omni Design System Updates

### Priority 1: Core Navigation & Authentication

#### 1. Auth Wrapper
**Route:** `/auth`
**File:** `lib/screens/auth_wrapper.dart`
**Current Status:** Uses CU Omni
**Updates Needed:**
- Verify all components use CUTheme
- Ensure loading states use custom Omni spinners (NOT CircularProgressIndicator)
- Custom navigation transitions (zero material)

#### 2. Login Screen
**Route:** `/login`
**File:** `lib/screens/login_screen_riverpod.dart`
**Current Status:** Uses CU Omni
**Updates Needed:**
- Header: "Sign In" with Geist 32px bold
- Subtitle with Geist 16px
- Round all buttons (borderRadius: 100)
- Custom text inputs (NO Material TextField)
- Add accessibility focus indicators
- Use CUOutlinedCard for form container

#### 3. AI Signup Screen
**Route:** `/ai-signup`
**File:** `lib/screens/ai_signup_screen.dart`
**Current Status:** Uses CU Omni
**Updates Needed:**
- Header: "Create Account" with Geist 32px bold
- Chat interface with CUOutlinedCard
- Round all action buttons
- Ensure Geist font throughout
- Custom message bubbles (zero material)

---

### Priority 2: Privacy & Section 1033 Compliance

#### 5. Privacy Settings
**Route:** `/privacy`
**File:** `lib/screens/privacy/privacy_settings_screen.dart`
**Updates Needed:**
- Header: "Privacy Settings" with Geist 32px bold
- Subtitle: "Manage your data and privacy preferences"
- Section 1033 export button (prominent, rounded)
- All cards use CUOutlinedCard
- Back button matching Accessibility Settings
- Custom switches (zero material)

#### 6. Connected Apps Screen
**Route:** `/privacy/connected-apps`
**File:** `lib/screens/privacy/connected_apps_screen.dart`
**Updates Needed:**
- Header: "Connected Apps" with Geist 32px bold
- Subtitle: "Manage third-party access to your data"
- List of apps with CUOutlinedCard
- Revoke access buttons (rounded, custom styled)
- Section 1033 compliance notice

#### 7. Data Export Screen
**Route:** `/privacy/data-export`
**File:** `lib/screens/privacy/data_export_screen.dart`
**Updates Needed:**
- Header: "Export Your Data" with Geist 32px bold
- Subtitle: "Download your financial data (Section 1033)"
- Custom radio cards (NO Material Radio)
- Large rounded "Export" button
- Custom progress indicator (zero material)

---

## Zero Material Design Standards

### ❌ NEVER USE THESE (Material Components)
```dart
// PROHIBITED - Material Design Components
Material()
MaterialApp()
Scaffold()
AppBar()
FloatingActionButton()
TextField() // Use custom input instead
CircularProgressIndicator() // Use custom spinner
LinearProgressIndicator() // Use custom progress bar
Checkbox() // Use custom checkbox
Radio() // Use custom radio button
Switch() // Use custom toggle switch
MaterialButton()
RaisedButton()
FlatButton()
```

### ✅ ALWAYS USE THESE (Omni Components)
```dart
// APPROVED - CU Omni Design System
CUApp()
CUTheme.of(context)
CUOutlinedCard()
CUColorScheme
Container() // Base Flutter widget
CustomScrollView() // Base Flutter widget
GestureDetector() // Base Flutter widget
Text() with fontFamily: 'Geist'
```

---

## Typography System (Geist Font Only)

```dart
// Page Headers
TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  fontFamily: 'Geist',
  color: Colors.grey.shade900,
)

// Subtitles
TextStyle(
  fontSize: 16,
  fontFamily: 'Geist',
  color: Colors.grey.shade600,
)

// Section Headers
TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  fontFamily: 'Geist',
  color: Colors.grey.shade900,
)

// Body Text
TextStyle(
  fontSize: 16,
  fontFamily: 'Geist',
  color: Colors.grey.shade900,
)

// Labels
TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  fontFamily: 'Geist',
  letterSpacing: 0.5,
  color: Colors.grey.shade600,
)

// Button Text
TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w600,
  fontFamily: 'Geist',
)
```

---

## Custom Component Patterns

### Buttons (Zero Material)
```dart
// Primary Button
GestureDetector(
  onTap: () => handleTap(),
  child: Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    decoration: BoxDecoration(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(
      'Button Text',
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontFamily: 'Geist',
      ),
    ),
  ),
)

// Disabled Button
Opacity(
  opacity: 0.4,
  child: Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: Colors.grey.shade900,
      borderRadius: BorderRadius.circular(100),
    ),
    child: // content
  ),
)
```

### Cards (CU Omni)
```dart
// Standard Card
CUOutlinedCard(
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: // content
  ),
)

// Tappable Card
CUOutlinedCard(
  onTap: () => handleTap(),
  child: // content
)

// Custom Elevated Card
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 12,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  padding: const EdgeInsets.all(20),
  child: // content
)
```

### Custom Toggle Switch (Zero Material)
```dart
GestureDetector(
  onTap: () => onChanged(!value),
  child: Container(
    width: 48,
    height: 28,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: value
          ? theme.colorScheme.primary
          : Colors.grey.shade300,
    ),
    child: AnimatedAlign(
      duration: const Duration(milliseconds: 200),
      alignment: value
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(2),
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
      ),
    ),
  ),
)
```

### Custom Radio Button (Zero Material)
```dart
Container(
  width: 24,
  height: 24,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(
      color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400,
      width: 2,
    ),
    color: Colors.white,
  ),
  child: isSelected
      ? Center(
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary,
            ),
          ),
        )
      : null,
)
```

### Custom Text Input (Zero Material)
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: Colors.grey.shade300,
      width: 1,
    ),
  ),
  child: EditableText(
    controller: controller,
    focusNode: focusNode,
    style: TextStyle(
      fontSize: 16,
      fontFamily: 'Geist',
      color: Colors.grey.shade900,
    ),
    cursorColor: theme.colorScheme.primary,
    backgroundCursorColor: Colors.grey.shade200,
  ),
)
```

---

## Color Palette (Zero Material)

```dart
// Background
const Color(0xFFF5F5F5)

// Surface/Cards
Colors.white

// Primary Text
Colors.grey.shade900

// Secondary Text
Colors.grey.shade600

// Borders/Dividers
Colors.grey.shade200
Colors.grey.shade300

// Disabled
Colors.grey.shade400 with Opacity(0.4)

// Theme Colors (from CUColorScheme)
theme.colorScheme.primary
theme.colorScheme.onSurface
theme.colorScheme.surface
```

---

## Section 1033 Compliance (Zero Material Implementation)

### Data Export Button
```dart
GestureDetector(
  onTap: () => exportData(),
  child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(100),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.primary.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.download, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          'Export My Data',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'Geist',
          ),
        ),
      ],
    ),
  ),
)
```

### Section 1033 Notice Banner
```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: theme.colorScheme.primary.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: theme.colorScheme.primary.withOpacity(0.2),
      width: 1,
    ),
  ),
  child: Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.shield_outlined,
          color: Colors.white,
          size: 20,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Section 1033 Data Rights',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'You can now export your financial data under federal consumer protection rules',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Geist',
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
)
```

---

## Implementation Checklist

### Global Rules
- [ ] NEVER import Material components
- [ ] ALWAYS use CU Omni design system
- [ ] ALWAYS specify `fontFamily: 'Geist'`
- [ ] Use Container + GestureDetector for buttons
- [ ] Use CUOutlinedCard for cards
- [ ] Custom implementations for all interactive elements
- [ ] BorderRadius.circular(100) for buttons
- [ ] BorderRadius.circular(16) for cards
- [ ] BorderRadius.circular(12) for inputs

### Per-Screen Updates
- [ ] Remove any Material imports
- [ ] Replace Material components with custom Omni equivalents
- [ ] Add proper header with Geist typography
- [ ] Use CUTheme.of(context) for theme access
- [ ] Round all buttons to circular(100)
- [ ] Update all cards to CUOutlinedCard or custom Container
- [ ] Verify Geist font on all text
- [ ] Test accessibility
- [ ] Test color transformations (accessibility service)

---

## Routes Summary

### Authentication Flow (4 routes)
- `/auth` - AuthWrapper
- `/login` - LoginScreenRiverpod
- `/ai-signup` - AISignupScreen
- `/chat-signup` - ChatSignupScreen

### Privacy & 1033 Compliance (4 routes)
- `/privacy` - PrivacySettingsScreen
- `/privacy/connected-apps` - ConnectedAppsScreen
- `/privacy/data-export` - DataExportScreen
- `/privacy/access-history` - DataAccessHistoryScreen

### Core App (20+ additional routes)
See exploration results for complete list of all screens requiring updates.

---

## Key Principles

1. **Zero Material Design** - Custom components only
2. **CU Omni First** - Use design system components
3. **Geist Typography** - All text uses Geist font
4. **Accessibility** - Color transformations, high contrast support
5. **Section 1033** - Prominent data export, access transparency
6. **Consistent Styling** - Rounded buttons, clean cards, minimal shadows

---

## Resources

- Design System Package: `cu_design_system_omni`
- Theme Implementation: `lib/main.dart`
- Accessibility Service: `lib/services/accessibility_service.dart`
- Example Screens:
  - `lib/screens/simple_dashboard_screen.dart` (home)
  - `lib/screens/accessibility_settings_screen.dart` (settings)
  - `lib/screens/settings_screen.dart` (main settings)

*Last Updated: 2025-11-07*
*Design System: CU Omni (Zero Material)*
