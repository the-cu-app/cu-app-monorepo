/// CU ListTile Widget
///
/// LIST ITEM
/// - CU typography, icons
/// - Zero Material dependencies
///
/// Usage:
/// ```dart
/// CUListTile(
///   leading: CUIcon(icon: CUIcons.accounts),
///   title: CUText('Account'),
///   trailing: CUIcon(icon: CUIcons.chevronRight),
/// )
/// ```
import 'package:flutter/widgets.dart';
import '../foundation/index.dart';
import '../primitives/index.dart';

class CUListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  const CUListTile({
    Key? key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: CUPadding(
        padding: EdgeInsets.symmetric(
          horizontal: CUSpacing.md,
          vertical: CUSpacing.sm,
        ),
        child: CURow(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              CUSizedBox(width: CUSpacing.md),
            ],
            CUExpanded(
              child: CUColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null) title!,
                  if (subtitle != null) ...[
                    CUSizedBox(height: CUSpacing.xs),
                    Opacity(
                      opacity: 0.7,
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              CUSizedBox(width: CUSpacing.md),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
