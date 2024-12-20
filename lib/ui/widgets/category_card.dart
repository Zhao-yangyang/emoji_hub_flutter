import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;

  const CategoryCard({
    super.key,
    required this.name,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'category_$name',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          splashColor: AppTheme.accent.withOpacity(0.1),
          highlightColor: AppTheme.accent.withOpacity(0.05),
          child: TweenAnimationBuilder<double>(
            duration: AppConstants.animationDuration,
            tween: Tween<double>(
              begin: 0.95,
              end: isSelected ? 1.05 : 1.0,
            ),
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: AnimatedContainer(
              duration: AppConstants.animationDuration,
              width: 100,
              margin: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacing / 2,
                vertical: AppConstants.spacing,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isSelected
                        ? AppTheme.accent.withOpacity(0.2)
                        : AppTheme.surface,
                    isSelected
                        ? AppTheme.accent.withOpacity(0.1)
                        : const Color(0xFF3A3A3A),
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(AppConstants.cardBorderRadius),
                border: isSelected
                    ? Border.all(color: AppTheme.accent, width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppTheme.accent.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
                    size: AppConstants.iconSize * 1.5,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: TextStyle(
                      color:
                          isSelected ? AppTheme.accent : AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
