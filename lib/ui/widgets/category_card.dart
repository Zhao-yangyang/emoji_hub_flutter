import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/category.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'category_${category.name}',
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
              height: 80,
              margin: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacing / 2,
                vertical: AppConstants.spacing / 2,
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                    IconData(category.icon, fontFamily: 'MaterialIcons'),
                    color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
                    size: AppConstants.iconSize * 1.5,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
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
