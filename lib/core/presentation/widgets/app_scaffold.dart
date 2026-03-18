import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomSheet,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomSheet;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  static bool _railExtended = false;

  static const _destinations = <_NavDestination>[
    _NavDestination(
      'Dashboard',
      '/dashboard',
      Icons.grid_view_outlined,
      Icons.grid_view_rounded,
    ),
    _NavDestination(
      'Budgets',
      '/budgets',
      Icons.pie_chart_outline_rounded,
      Icons.pie_chart_rounded,
    ),
    _NavDestination(
      'Transactions',
      '/transactions',
      Icons.receipt_long_outlined,
      Icons.receipt_long_rounded,
    ),
    _NavDestination(
      'Goals',
      '/goals',
      Icons.savings_outlined,
      Icons.savings_rounded,
    ),
    _NavDestination(
      'Accounts',
      '/accounts',
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet_rounded,
      mobileMoreItem: true,
    ),
    _NavDestination(
      'Categories',
      '/categories',
      Icons.label_outline_rounded,
      Icons.label_rounded,
      mobileMoreItem: true,
    ),
    _NavDestination(
      'Insights',
      '/insights',
      Icons.bar_chart_outlined,
      Icons.bar_chart_rounded,
      mobileMoreItem: true,
    ),
    _NavDestination(
      'Settings',
      '/settings',
      Icons.settings_outlined,
      Icons.settings_rounded,
      mobileMoreItem: true,
    ),
  ];

  static final _mobileMainDestinations = _destinations
      .where((d) => !d.mobileMoreItem)
      .toList();

  int _selectedIndex(String location) {
    return _destinations
        .indexWhere((d) => location.startsWith(d.path))
        .clamp(0, _destinations.length - 1);
  }

  int _bottomNavIndex(String location) {
    final mainIdx = _mobileMainDestinations.indexWhere(
      (d) => location.startsWith(d.path),
    );
    if (mainIdx != -1) return mainIdx;

    final isMore = _destinations
        .where((d) => d.mobileMoreItem)
        .any((d) => location.startsWith(d.path));

    return isMore ? _mobileMainDestinations.length : 0;
  }

  void _onBottomNavTap(BuildContext context, int index) {
    if (index < _mobileMainDestinations.length) {
      context.go(_mobileMainDestinations[index].path);
    } else {
      _showMoreSheet(context);
    }
  }

  void _showMoreSheet(BuildContext context) {
    final moreItems = _destinations.where((d) => d.mobileMoreItem).toList();
    final location = GoRouterState.of(context).uri.toString();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: moreItems.map((d) {
            final selected = location.startsWith(d.path);
            return ListTile(
              leading: Icon(selected ? d.selectedIcon : d.icon),
              title: Text(d.label),
              selected: selected,
              onTap: () {
                Navigator.pop(context);
                context.go(d.path);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return isMobile
        ? _buildMobile(context, colorTheme)
        : _buildDesktop(context, colorTheme);
  }

  Widget _buildMobile(BuildContext context, ColorScheme colorTheme) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _bottomNavIndex(location);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: widget.actions,
        backgroundColor: colorTheme.surface,
        shape: Border(
          bottom: BorderSide(
            color: colorTheme.outlineVariant.withAlpha(80),
            width: 0.5,
          ),
        ),
      ),
      body: widget.body,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colorTheme.outlineVariant, width: 0.5),
          ),
        ),
        child: NavigationBar(
          backgroundColor: colorTheme.surface,
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) => _onBottomNavTap(context, i),
          destinations: [
            ..._mobileMainDestinations.map(
              (d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
            ),
            const NavigationDestination(
              icon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context, ColorScheme colorTheme) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _selectedIndex(location);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorTheme.surface,
        shape: Border(
          bottom: BorderSide(
            color: colorTheme.outlineVariant.withAlpha(80),
            width: 0.5,
          ),
        ),
        title: Row(
          children: [
            SizedBox(
              width: 48,
              child: Tooltip(
                message: _railExtended ? 'Collapse Sidebar' : 'Expand Sidebar',
                child: IconButton(
                  icon: const Icon(Icons.menu, size: 24),
                  onPressed: () =>
                      setState(() => _railExtended = !_railExtended),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(widget.title),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: widget.actions,
      ),
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: colorTheme.surface,
            selectedIndex: selectedIndex,
            extended: _railExtended,
            onDestinationSelected: (index) {
              context.go(_destinations[index].path);
            },
            destinations: _destinations.map((d) {
              return NavigationRailDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: Text(d.label),
              );
            }).toList(),
          ),
          Container(width: 1, color: colorTheme.outlineVariant.withAlpha(80)),
          Expanded(child: _ContentArea(child: widget.body)),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      bottomSheet: widget.bottomSheet,
    );
  }
}

class _ContentArea extends StatelessWidget {
  const _ContentArea({required this.child});

  final Widget child;

  static const double _maxWidth = 1184;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width > 1280) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: child,
        ),
      );
    }

    if (width > 900) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: child,
      );
    }

    return child;
  }
}

class _NavDestination {
  const _NavDestination(
    this.label,
    this.path,
    this.icon,
    this.selectedIcon, {
    this.mobileMoreItem = false,
  });

  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final bool mobileMoreItem;
}
