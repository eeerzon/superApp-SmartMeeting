/// Fixed landscape layout. The app is locked to landscape and designed
/// against a 1280x800 tablet; content areas stretch horizontally.
abstract final class AppLayout {
  static const designWidth = 1280.0;
  static const designHeight = 800.0;

  static const sidebarWidth = 220.0;
  static const topBarHeight = 72.0;
  static const pagePadding = 24.0;
  static const gap = 16.0;

  /// Dashboard device grid.
  static const gridColumns = 3;

  /// Device management: unit list on the left of the detail panel.
  static const unitListWidth = 260.0;

  /// User page: profile column width.
  static const profileColumnWidth = 340.0;
}
