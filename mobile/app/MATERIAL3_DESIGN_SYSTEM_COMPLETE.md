# Material 3 Financial Services App - Complete Design System Documentation

## Executive Summary

This document provides a comprehensive A-Z design system implementation plan for a Flutter-based financial services application. The app currently contains inconsistencies where some components use proper Material 3 design tokens while others use hardcoded values or approximated implementations. This documentation identifies every widget, component, and design pattern, providing exhaustive implementation guidelines to achieve complete Material 3 compliance.

## Table of Contents

1. [Design System Architecture](#design-system-architecture)
2. [Color System](#color-system)
3. [Typography System](#typography-system)
4. [Component Library A-Z](#component-library-a-z)
5. [Layout & Spacing](#layout--spacing)
6. [Motion & Animation](#motion--animation)
7. [Implementation Plan](#implementation-plan)
8. [Quality Assurance](#quality-assurance)

---

## Design System Architecture

### Current State Analysis
The application contains a hybrid of proper Material 3 components and custom implementations that approximate Material 3 styling without using the proper design tokens. This creates inconsistencies in:
- Color usage (hardcoded hex values vs semantic color tokens)
- Typography scaling and weights
- Component spacing and proportions
- Interactive states and animations
- Accessibility features

### Target State
A fully compliant Material 3 design system where every visual element uses proper design tokens, ensuring:
- Consistent theming across light/dark modes
- Proper accessibility contrast ratios
- Responsive scaling across device sizes
- Semantic color usage for better maintainability

---

## Color System

### Current Issues
- Hardcoded colors like `Colors.grey.shade600`, `Colors.blue`, etc.
- Inconsistent use of surface colors
- Missing semantic color roles for financial data

### Material 3 Color Implementation

#### Primary Color Tokens
```dart
// Replace all instances of hardcoded blues
Theme.of(context).colorScheme.primary         // Main brand color
Theme.of(context).colorScheme.onPrimary       // Text/icons on primary
Theme.of(context).colorScheme.primaryContainer // Subtle primary backgrounds
Theme.of(context).colorScheme.onPrimaryContainer // Text on primary container
```

#### Surface Color Tokens
```dart
// Replace hardcoded backgrounds
Theme.of(context).colorScheme.surface         // Card backgrounds
Theme.of(context).colorScheme.onSurface       // Text on surface
Theme.of(context).colorScheme.surfaceVariant  // Secondary backgrounds
Theme.of(context).colorScheme.onSurfaceVariant // Secondary text
```

#### Financial-Specific Color Extensions
```dart
extension FinancialColors on ColorScheme {
  Color get positive => Color(0xFF00C851);     // Gains, deposits
  Color get negative => Color(0xFFFF4444);     // Losses, withdrawals
  Color get warning => Color(0xFFFFBB33);      // Alerts, pending
  Color get neutral => onSurfaceVariant;       // No change values
}
```

---

## Typography System

### Current Issues
- Inconsistent font weights and sizes
- Missing proper Material 3 type roles
- Hardcoded TextStyle definitions

### Material 3 Typography Implementation

#### Display Styles (Large headings)
```dart
Theme.of(context).textTheme.displayLarge      // 57sp, -0.25sp letter spacing
Theme.of(context).textTheme.displayMedium     // 45sp, 0sp letter spacing  
Theme.of(context).textTheme.displaySmall      // 36sp, 0sp letter spacing
```

#### Headline Styles (Section headers)
```dart
Theme.of(context).textTheme.headlineLarge     // 32sp, 0sp letter spacing
Theme.of(context).textTheme.headlineMedium    // 28sp, 0sp letter spacing
Theme.of(context).textTheme.headlineSmall     // 24sp, 0sp letter spacing
```

#### Title Styles (Card headers, important text)
```dart
Theme.of(context).textTheme.titleLarge        // 22sp, 0sp letter spacing
Theme.of(context).textTheme.titleMedium       // 16sp, 0.15sp letter spacing
Theme.of(context).textTheme.titleSmall        // 14sp, 0.1sp letter spacing
```

#### Body Styles (Primary content)
```dart
Theme.of(context).textTheme.bodyLarge         // 16sp, 0.5sp letter spacing
Theme.of(context).textTheme.bodyMedium        // 14sp, 0.25sp letter spacing
Theme.of(context).textTheme.bodySmall         // 12sp, 0.4sp letter spacing
```

#### Label Styles (Buttons, captions)
```dart
Theme.of(context).textTheme.labelLarge        // 14sp, 0.1sp letter spacing
Theme.of(context).textTheme.labelMedium       // 12sp, 0.5sp letter spacing
Theme.of(context).textTheme.labelSmall        // 11sp, 0.5sp letter spacing
```

---

## Component Library A-Z

### AppBar Components

#### M3AppBar (Standard Implementation)
```dart
class M3AppBar extends StatelessWidget implements PreferredSizeWidget {
  const M3AppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
      foregroundColor: foregroundColor ?? Theme.of(context).colorScheme.onSurface,
      elevation: elevation,
      centerTitle: centerTitle,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
```

#### FinancialAppBar (Specialized for financial context)
```dart
class FinancialAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FinancialAppBar({
    super.key,
    required this.title,
    this.totalBalance,
    this.accountCount,
    this.profileAction,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (totalBalance != null)
            Text(
              NumberFormat.currency(symbol: '\$').format(totalBalance),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      actions: [
        if (profileAction != null) profileAction!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
```

### Button Components

#### M3FilledButton (Primary actions)
```dart
class M3FilledButton extends StatelessWidget {
  const M3FilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 40),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: icon != null 
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon!,
              const SizedBox(width: 8),
              child,
            ],
          )
        : child,
    );
  }
}
```

#### M3OutlinedButton (Secondary actions)
```dart
class M3OutlinedButton extends StatelessWidget {
  const M3OutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 40),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: icon != null 
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon!,
              const SizedBox(width: 8),
              child,
            ],
          )
        : child,
    );
  }
}
```

### Card Components

#### M3Card (Standard elevation card)
```dart
class M3Card extends StatelessWidget {
  const M3Card({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding = const EdgeInsets.all(16),
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      elevation: elevation ?? 1,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
```

#### AccountCard (Financial account representation)
```dart
class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.accountName,
    required this.accountType,
    required this.balance,
    required this.available,
    required this.mask,
    this.onTap,
    this.institutionLogo,
  });

  @override
  Widget build(BuildContext context) {
    return M3Card(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (institutionLogo != null) ...[
                institutionLogo!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accountName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$accountType •••• $mask',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Balance',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(symbol: '\$').format(balance),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              if (available != balance)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Available',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(symbol: '\$').format(available),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### Chip Components

#### M3FilterChip (Selection filtering)
```dart
class M3FilterChip extends StatelessWidget {
  const M3FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      avatar: avatar,
      labelStyle: Theme.of(context).textTheme.labelLarge,
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.secondaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onSecondaryContainer,
      side: BorderSide(
        color: selected 
          ? Theme.of(context).colorScheme.secondary
          : Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
```

### Dialog Components

#### M3AlertDialog (Standard confirmation dialog)
```dart
class M3AlertDialog extends StatelessWidget {
  const M3AlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title,
      content: content,
      actions: actions,
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      titleTextStyle: Theme.of(context).textTheme.headlineSmall,
      contentTextStyle: Theme.of(context).textTheme.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
    );
  }
}
```

#### TransferConfirmationDialog (Financial operation confirmation)
```dart
class TransferConfirmationDialog extends StatelessWidget {
  const TransferConfirmationDialog({
    super.key,
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return M3AlertDialog(
      title: Text('Confirm Transfer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transfer Details',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(context, 'From', fromAccount),
          _buildDetailRow(context, 'To', toAccount),
          _buildDetailRow(
            context, 
            'Amount', 
            NumberFormat.currency(symbol: '\$').format(amount),
            isAmount: true,
          ),
        ],
      ),
      actions: [
        M3OutlinedButton(
          onPressed: onCancel,
          child: Text('Cancel'),
        ),
        M3FilledButton(
          onPressed: onConfirm,
          child: Text('Confirm'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context, 
    String label, 
    String value, 
    {bool isAmount = false}
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: isAmount 
              ? Theme.of(context).textTheme.titleMedium
              : Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
```

### FAB Components

#### M3FloatingActionButton (Primary floating action)
```dart
class M3FloatingActionButton extends StatelessWidget {
  const M3FloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
      foregroundColor: foregroundColor ?? Theme.of(context).colorScheme.onPrimaryContainer,
      elevation: 6,
      child: child,
    );
  }
}
```

### Form Field Components

#### M3TextField (Standard text input)
```dart
class M3TextField extends StatelessWidget {
  const M3TextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      maxLines: maxLines,
      enabled: enabled,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}
```

#### AmountTextField (Currency input field)
```dart
class AmountTextField extends StatelessWidget {
  const AmountTextField({
    super.key,
    this.controller,
    this.labelText = 'Amount',
    this.onChanged,
    this.validator,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    return M3TextField(
      controller: controller,
      labelText: labelText,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      validator: validator,
      prefixIcon: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          currencySymbol,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
```

### Icon Components

#### M3Icon (Standard icon with proper theming)
```dart
class M3Icon extends StatelessWidget {
  const M3Icon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size ?? 24,
      color: color ?? Theme.of(context).iconTheme.color,
      semanticLabel: semanticLabel,
    );
  }
}
```

#### FinancialIcon (Icons with financial context)
```dart
class FinancialIcon extends StatelessWidget {
  const FinancialIcon({
    super.key,
    required this.type,
    this.size = 24,
    this.color,
  });

  final FinancialIconType type;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color? iconColor = color;

    switch (type) {
      case FinancialIconType.deposit:
        iconData = Icons.arrow_downward;
        iconColor ??= Theme.of(context).extension<FinancialColors>()?.positive;
        break;
      case FinancialIconType.withdrawal:
        iconData = Icons.arrow_upward;
        iconColor ??= Theme.of(context).extension<FinancialColors>()?.negative;
        break;
      case FinancialIconType.transfer:
        iconData = Icons.swap_horiz;
        iconColor ??= Theme.of(context).colorScheme.primary;
        break;
      case FinancialIconType.pending:
        iconData = Icons.schedule;
        iconColor ??= Theme.of(context).extension<FinancialColors>()?.warning;
        break;
    }

    return M3Icon(
      iconData,
      size: size,
      color: iconColor,
    );
  }
}

enum FinancialIconType {
  deposit,
  withdrawal,
  transfer,
  pending,
}
```

### List Components

#### M3ListTile (Standard list item)
```dart
class M3ListTile extends StatelessWidget {
  const M3ListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      titleTextStyle: Theme.of(context).textTheme.bodyLarge,
      subtitleTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
```

#### TransactionListTile (Financial transaction representation)
```dart
class TransactionListTile extends StatelessWidget {
  const TransactionListTile({
    super.key,
    required this.merchantName,
    required this.category,
    required this.amount,
    required this.date,
    this.pending = false,
    this.onTap,
    this.merchantLogo,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = amount > 0;
    final amountColor = isPositive 
      ? Theme.of(context).extension<FinancialColors>()?.positive
      : Theme.of(context).extension<FinancialColors>()?.negative;

    return M3ListTile(
      leading: merchantLogo ?? Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: M3Icon(
          _getCategoryIcon(category),
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(merchantName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category),
          Text(
            DateFormat('MMM dd, yyyy').format(date),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isPositive ? '+' : ''}${NumberFormat.currency(symbol: '\$').format(amount)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (pending)
            Text(
              'Pending',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).extension<FinancialColors>()?.warning,
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  IconData _getCategoryIcon(String category) {
    // Map categories to appropriate icons
    final categoryMap = {
      'Food and Drink': Icons.restaurant,
      'Transportation': Icons.directions_car,
      'Shopping': Icons.shopping_bag,
      'Bills': Icons.receipt,
      'Entertainment': Icons.movie,
    };
    return categoryMap[category] ?? Icons.category;
  }
}
```

### Navigation Components

#### M3NavigationBar (Bottom navigation)
```dart
class M3NavigationBar extends StatelessWidget {
  const M3NavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations,
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    );
  }
}
```

#### M3NavigationRail (Side navigation for larger screens)
```dart
class M3NavigationRail extends StatelessWidget {
  const M3NavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.extended = false,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations,
      extended: extended,
      leading: leading,
      trailing: trailing,
      backgroundColor: Theme.of(context).colorScheme.surface,
      indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
      selectedIconTheme: IconThemeData(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
      selectedLabelTextStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
      unselectedIconTheme: IconThemeData(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      unselectedLabelTextStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
```

### Progress Indicators

#### M3LinearProgressIndicator (Linear progress)
```dart
class M3LinearProgressIndicator extends StatelessWidget {
  const M3LinearProgressIndicator({
    super.key,
    this.value,
    this.backgroundColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: value,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surfaceVariant,
      valueColor: AlwaysStoppedAnimation<Color>(
        valueColor ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
```

#### BudgetProgressIndicator (Budget usage visualization)
```dart
class BudgetProgressIndicator extends StatelessWidget {
  const BudgetProgressIndicator({
    super.key,
    required this.spent,
    required this.budget,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final progress = spent / budget;
    final isOverBudget = progress > 1.0;
    
    Color progressColor;
    if (isOverBudget) {
      progressColor = Theme.of(context).extension<FinancialColors>()!.negative;
    } else if (progress > 0.8) {
      progressColor = Theme.of(context).extension<FinancialColors>()!.warning;
    } else {
      progressColor = Theme.of(context).colorScheme.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              '${NumberFormat.currency(symbol: '\$').format(spent)} / ${NumberFormat.currency(symbol: '\$').format(budget)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        M3LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          valueColor: progressColor,
        ),
        if (isOverBudget) ...[
          const SizedBox(height: 4),
          Text(
            'Over budget by ${NumberFormat.currency(symbol: '\$').format(spent - budget)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: progressColor,
            ),
          ),
        ],
      ],
    );
  }
}
```

### Slider Components

#### M3Slider (Standard slider)
```dart
class M3Slider extends StatelessWidget {
  const M3Slider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
      label: label,
      activeColor: Theme.of(context).colorScheme.primary,
      inactiveColor: Theme.of(context).colorScheme.surfaceVariant,
      thumbColor: Theme.of(context).colorScheme.primary,
    );
  }
}
```

### Switch Components

#### M3Switch (Boolean toggle)
```dart
class M3Switch extends StatelessWidget {
  const M3Switch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
      activeTrackColor: Theme.of(context).colorScheme.primaryContainer,
      inactiveThumbColor: Theme.of(context).colorScheme.outline,
      inactiveTrackColor: Theme.of(context).colorScheme.surfaceVariant,
    );
  }
}
```

### Tab Components

#### M3TabBar (Tab navigation)
```dart
class M3TabBar extends StatelessWidget implements PreferredSizeWidget {
  const M3TabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      tabs: tabs,
      controller: controller,
      isScrollable: isScrollable,
      indicatorColor: Theme.of(context).colorScheme.primary,
      labelColor: Theme.of(context).colorScheme.primary,
      unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
      labelStyle: Theme.of(context).textTheme.titleSmall,
      unselectedLabelStyle: Theme.of(context).textTheme.titleSmall,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);
}
```

### Toast/Snackbar Components

#### M3SnackBar (Contextual messages)
```dart
class M3SnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
    SnackBarType type = SnackBarType.info,
  }) {
    Color backgroundColor;
    Color contentColor;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = Theme.of(context).extension<FinancialColors>()!.positive;
        contentColor = Colors.white;
        break;
      case SnackBarType.error:
        backgroundColor = Theme.of(context).colorScheme.error;
        contentColor = Theme.of(context).colorScheme.onError;
        break;
      case SnackBarType.warning:
        backgroundColor = Theme.of(context).extension<FinancialColors>()!.warning;
        contentColor = Colors.black;
        break;
      case SnackBarType.info:
      default:
        backgroundColor = Theme.of(context).colorScheme.inverseSurface;
        contentColor = Theme.of(context).colorScheme.onInverseSurface;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: contentColor,
          ),
        ),
        action: action,
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

enum SnackBarType {
  info,
  success,
  warning,
  error,
}
```

### Tooltip Components

#### M3Tooltip (Hover/long-press information)
```dart
class M3Tooltip extends StatelessWidget {
  const M3Tooltip({
    super.key,
    required this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onInverseSurface,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}
```

---

## Layout & Spacing

### Spacing System
```dart
class M3Spacing {
  static const double xs = 4.0;   // 4dp
  static const double sm = 8.0;   // 8dp
  static const double md = 16.0;  // 16dp
  static const double lg = 24.0;  // 24dp
  static const double xl = 32.0;  // 32dp
  static const double xxl = 40.0; // 40dp
}
```

### Grid System
```dart
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return mobile;
        } else if (constraints.maxWidth < 1200) {
          return tablet;
        } else {
          return desktop;
        }
      },
    );
  }
}
```

---

## Motion & Animation

### Standard Transitions
```dart
class M3PageRoute<T> extends PageRouteBuilder<T> {
  M3PageRoute({
    required this.child,
    RouteSettings? settings,
  }) : super(
    settings: settings,
    pageBuilder: (context, animation, _) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: animation.drive(
          Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut)),
        ),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );

  final Widget child;
}
```

### Micro-interactions
```dart
class AnimatedBalance extends StatefulWidget {
  const AnimatedBalance({
    super.key,
    required this.balance,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedBalance> createState() => _AnimatedBalanceState();
}

class _AnimatedBalanceState extends State<AnimatedBalance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousBalance = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: _previousBalance,
      end: widget.balance,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedBalance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.balance != widget.balance) {
      _previousBalance = oldWidget.balance;
      _animation = Tween<double>(
        begin: _previousBalance,
        end: widget.balance,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          NumberFormat.currency(symbol: '\$').format(_animation.value),
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

## Implementation Plan

### Phase 1: Foundation (Week 1-2)
1. **Design Token Implementation**
   - Create color scheme extensions
   - Implement typography system
   - Set up spacing constants
   - Configure theme data

2. **Core Component Audit**
   - Identify all existing approximated components
   - Document current hardcoded values
   - Create replacement component mapping

### Phase 2: Component Replacement (Week 3-4)
1. **Navigation Components**
   - Replace custom AppBar with M3AppBar
   - Update NavigationBar/NavigationRail
   - Implement proper routing transitions

2. **Data Display Components**
   - Replace hardcoded cards with AccountCard/M3Card
   - Update list tiles with proper theming
   - Implement consistent icon usage

### Phase 3: Interactive Components (Week 5-6)
1. **Forms and Inputs**
   - Replace TextField implementations
   - Update button styling
   - Implement proper validation states

2. **Feedback Components**
   - Standardize SnackBar usage
   - Implement consistent dialog patterns
   - Add proper loading states

### Phase 4: Advanced Features (Week 7-8)
1. **Animations and Transitions**
   - Implement micro-interactions
   - Add proper page transitions
   - Create animated financial visualizations

2. **Accessibility and Polish**
   - Ensure proper contrast ratios
   - Add semantic labels
   - Test with screen readers
   - Implement proper focus management

### Phase 5: Testing and Optimization (Week 9-10)
1. **Quality Assurance**
   - Automated theme compliance testing
   - Cross-device testing
   - Performance optimization
   - Final design review

---

## Quality Assurance

### Theme Compliance Checklist
- [ ] All colors use semantic color tokens
- [ ] All typography uses theme text styles
- [ ] All spacing uses standardized values
- [ ] All animations use Material motion curves
- [ ] All components support dark/light themes
- [ ] All interactive elements have proper states
- [ ] All components are accessible
- [ ] All financial data has appropriate formatting

### Testing Strategy
1. **Automated Tests**
   - Theme token usage verification
   - Component API consistency
   - Accessibility compliance

2. **Manual Testing**
   - Cross-device compatibility
   - Theme switching validation
   - User interaction flows

3. **Performance Testing**
   - Animation smoothness
   - Large dataset rendering
   - Memory usage optimization

This comprehensive design system ensures that every visual element in the financial application follows Material 3 guidelines while maintaining consistency, accessibility, and optimal user experience across all device sizes and interaction patterns.