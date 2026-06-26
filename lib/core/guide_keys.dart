import 'package:flutter/widgets.dart';

/// Hooks the guided tour into the app shell so it can switch bottom-nav tabs.
class GuideNav {
  /// Set by MainShell — switches the visible tab (0=Home … 4=Delivery).
  static void Function(int index)? switchTab;
}

/// GlobalKeys attached to the real on-screen controls the tour spotlights.
/// Widgets in the shell / tabs are always mounted (IndexedStack), so these
/// keys stay valid; pushed-screen keys resolve only while that screen is open.
class GuideKeys {
  // Home shell
  static final tabs = GlobalKey(debugLabel: 'guide.tabs');
  static final shortcuts = GlobalKey(debugLabel: 'guide.shortcuts');
  static final search = GlobalKey(debugLabel: 'guide.search');
  static final theme = GlobalKey(debugLabel: 'guide.theme');
  static final language = GlobalKey(debugLabel: 'guide.language');
  static final aiFab = GlobalKey(debugLabel: 'guide.aiFab');
  static final bottomNav = GlobalKey(debugLabel: 'guide.bottomNav');

  // Shop tab
  static final shopSearch = GlobalKey(debugLabel: 'guide.shopSearch');
  static final shopCategories = GlobalKey(debugLabel: 'guide.shopCategories');
  static final shopCart = GlobalKey(debugLabel: 'guide.shopCart');

  // Pushed screens
  static final productAddToCart = GlobalKey(debugLabel: 'guide.addToCart');
  static final productViewToggle = GlobalKey(debugLabel: 'guide.viewToggle');
  static final donateDirections = GlobalKey(debugLabel: 'guide.donateDirections');
}
