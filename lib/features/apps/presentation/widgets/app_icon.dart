import 'package:flutter/material.dart';

import '../../../../core/design/app_spacing.dart';
import '../../../../tv/domain/tv_domain.dart';
import '../../application/app_artwork_resolver.dart';

/// Renders a launchable app's icon: the bundled artwork
/// [AppArtworkResolver] resolves when this app is one this repo ships
/// approved artwork for, otherwise a generic placeholder - used by both
/// the Remote screen's Quick Apps row and the Apps screen so the two
/// never render this differently.
///
/// Never shows a broken-image placeholder: a resolved asset that
/// somehow fails to decode (a corrupt file, a packaging error) falls
/// back to the same generic icon an unrecognized app gets.
class AppIcon extends StatelessWidget {
  const AppIcon({
    required this.app,
    this.size = 44,
    this.bordered = true,
    super.key,
  });

  final TvApplication app;
  final double size;

  /// A hairline border in the theme's divider color - on by default so
  /// artwork with a light or transparent edge (some app icons are flush
  /// with their own background) still reads as a distinct tile.
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assetPath = AppArtworkResolver.resolveForApp(app);
    final fallbackIconSize = size * 0.5;
    final radius = BorderRadius.circular(AppRadius.md);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: radius,
          border: bordered ? Border.all(color: theme.dividerColor) : null,
        ),
        alignment: Alignment.center,
        child: assetPath == null
            ? Icon(
                Icons.smart_display_outlined,
                size: fallbackIconSize,
                color: theme.colorScheme.secondary,
              )
            : Image.asset(
                assetPath,
                width: size,
                height: size,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.smart_display_outlined,
                  size: fallbackIconSize,
                  color: theme.colorScheme.secondary,
                ),
              ),
      ),
    );
  }
}
