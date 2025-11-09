import 'package:flutter/material.dart';

class ConsistentListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSelected;
  final EdgeInsetsGeometry? contentPadding;
  final Color? backgroundColor;
  final bool showDivider;
  final bool enabled;

  const ConsistentListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isSelected = false,
    this.contentPadding,
    this.backgroundColor,
    this.showDivider = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final tile = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? 
               (isSelected 
                  ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                  : Colors.transparent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        enabled: enabled,
        selected: isSelected,
        selectedTileColor: Colors.transparent,
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: leading != null ? SizedBox(
          width: 48,
          height: 48,
          child: Center(child: leading),
        ) : null,
        title: DefaultTextStyle(
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: enabled 
                ? (isSelected 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurface)
                : theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          child: title ?? const SizedBox.shrink(),
        ),
        subtitle: subtitle != null ? DefaultTextStyle(
          style: TextStyle(
            fontSize: 14,
            color: enabled
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          child: subtitle!,
        ) : null,
        trailing: trailing,
        onTap: enabled ? onTap : null,
      ),
    );

    if (showDivider) {
      return Column(
        children: [
          tile,
          Divider(
            height: 1,
            indent: 64,
            endIndent: 16,
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ],
      );
    }

    return tile;
  }
}

class ConsistentListTileLeading extends StatelessWidget {
  final IconData? icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final Widget? child;
  final bool showBorder;

  const ConsistentListTileLeading({
    super.key,
    this.icon,
    this.backgroundColor,
    this.iconColor,
    this.child,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.primaryContainer.withOpacity(0.3),
        shape: BoxShape.circle,
        border: showBorder 
            ? Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
                width: 1,
              )
            : null,
      ),
      child: Center(
        child: child ?? (icon != null 
            ? Icon(
                icon,
                size: 24,
                color: iconColor ?? theme.colorScheme.primary,
              )
            : const SizedBox.shrink()),
      ),
    );
  }
}

class ConsistentListTileTitle extends StatelessWidget {
  final String text;
  final FontWeight? fontWeight;
  final Color? color;

  const ConsistentListTileTitle({
    super.key,
    required this.text,
    this.fontWeight,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color ?? theme.colorScheme.onSurface,
      ),
    );
  }
}

class ConsistentListTileSubtitle extends StatelessWidget {
  final String text;
  final Color? color;

  const ConsistentListTileSubtitle({
    super.key,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: color ?? theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class ConsistentListTileTrailing extends StatelessWidget {
  final String? text;
  final String? secondaryText;
  final IconData? icon;
  final Color? color;
  final Widget? child;

  const ConsistentListTileTrailing({
    super.key,
    this.text,
    this.secondaryText,
    this.icon,
    this.color,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (child != null) return child!;
    
    if (icon != null) {
      return Icon(
        icon,
        color: color ?? theme.colorScheme.onSurfaceVariant,
        size: 24,
      );
    }

    if (text != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            text!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color ?? theme.colorScheme.onSurface,
            ),
          ),
          if (secondaryText != null)
            Text(
              secondaryText!,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}