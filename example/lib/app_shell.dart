import 'package:flutter/material.dart';

import 'catalog_screen.dart';
import 'models/user_profile.dart';
import 'profile_screen.dart';

/// Hosts catalog and profile destinations for the showcase app.
class ExampleAppShell extends StatefulWidget {
  const ExampleAppShell({
    super.key,
    this.initialTabIndex = 0,
    this.catalogProducts = mockSuccessProducts,
    this.catalogIsOffline = false,
    this.catalogIsLoadingMore = false,
    this.catalogPage,
    this.profile = mockProfileComplete,
    this.profileOrders = mockProfileOrders,
    this.profileShowVerification = false,
    this.profileIsLoading = false,
    this.selectedTabIndex,
    this.onTabChanged,
  });

  final int initialTabIndex;
  final List<Product> catalogProducts;
  final bool catalogIsOffline;
  final bool catalogIsLoadingMore;
  final Widget? catalogPage;
  final UserProfile profile;
  final List<ProfileOrder> profileOrders;
  final bool profileShowVerification;
  final bool profileIsLoading;
  final int? selectedTabIndex;
  final ValueChanged<int>? onTabChanged;

  @override
  State<ExampleAppShell> createState() => _ExampleAppShellState();
}

class _ExampleAppShellState extends State<ExampleAppShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.selectedTabIndex ?? widget.initialTabIndex;
  }

  @override
  void didUpdateWidget(covariant ExampleAppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final external = widget.selectedTabIndex;
    if (external != null && external != _index) {
      _index = external;
    } else if (widget.initialTabIndex != oldWidget.initialTabIndex &&
        widget.selectedTabIndex == null) {
      _index = widget.initialTabIndex;
    }
  }

  void _onDestinationSelected(int index) {
    setState(() => _index = index);
    widget.onTabChanged?.call(index);
  }

  /// Used by [ScenarioKit.onNavigateToScreen].
  @override
  Widget build(BuildContext context) {
    final catalogChild = widget.catalogPage ??
        ProductCatalogScreen(
          products: widget.catalogProducts,
          isOffline: widget.catalogIsOffline,
          isLoadingMore: widget.catalogIsLoadingMore,
        );

    final pages = <Widget>[
      catalogChild,
      widget.profileIsLoading
          ? const ProfileLoadingView()
          : ProfileScreen(
              profile: widget.profile,
              orders: widget.profileOrders,
              showVerificationBanner: widget.profileShowVerification,
            ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Catalog',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}