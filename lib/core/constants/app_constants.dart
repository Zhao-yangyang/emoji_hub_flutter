class AppConstants {
  // 应用信息
  static const String appName = 'EmojiHub';
  static const String appVersion = '1.0.0';

  // 尺寸常量
  static const double cardBorderRadius = 16.0;
  static const double spacing = 16.0;
  static const double iconSize = 24.0;

  // 动画时长
  static const Duration animationDuration = Duration(milliseconds: 300);

  // 缓存配置
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const Duration cacheDuration = Duration(days: 7);
}
