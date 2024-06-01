// ignore_for_file: unused_element, no_logic_in_create_state, avoid_print, must_be_immutable

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavBar extends StatelessWidget {
  const NavBar({required this.child, super.key});

  static int _calculateSelectedIndex(context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location == '/') {
      return 0;
    } 
    if (location == '/create/diary') {
      return 1;
    }
    if (location == '/search') {
      return 2;
    }
    return 0;
  }
  // int selectedIndex = 0;
  void _onItemTapped(index, context) {
    switch (index) {
      case 0:
        GoRouter.of(context).replace('/');
      case 1:
        GoRouter.of(context).replace('/create/diary');
      case 2:
        GoRouter.of(context).replace('/search');
    }
  }
  static const List<NavigationDestination> navbarWidget = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_filled),
      label: 'Home',
    ),
     NavigationDestination(
      icon: Icon(Icons.create_outlined),
      selectedIcon: Icon(Icons.create_sharp),
      label: 'Create',
    ),
    NavigationDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search_sharp),
      label: 'Search',
    ),
  ];
  static const List<NavigationRailDestination> navbarWidgetWindows = [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_filled),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.create_outlined),
      selectedIcon: Icon(Icons.create_sharp),
      label: Text('Create'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search_sharp),
      label: Text('Search'),
    ),
  ];

  Widget _bottomNavbar(context) { 
    return NavigationBar(
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      selectedIndex: _calculateSelectedIndex(context),
      destinations: navbarWidget,
      onDestinationSelected: (int idx) => _onItemTapped(idx, context)
    );
  }
  Widget _sideNavbar(context) { 
    return NavigationRail(
      destinations: navbarWidgetWindows, 
      selectedIndex:  _calculateSelectedIndex(context),
      groupAlignment: 0,
      labelType: NavigationRailLabelType.selected,
      onDestinationSelected: (int idx) => _onItemTapped(idx, context)
    );
  }

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _bottomNavbar(context),
      body: child,
    );
    // if(kIsWeb) {
    //   return Scaffold(
    //     body: IndexedStack(
    //       index: _selectedIndex,
    //       children: _pages
    //     ),
    //     bottomNavigationBar: _bottomNavbar());
    // } 
    // else {
    //   if(Platform.isAndroid) {
    //     return Scaffold(
    //       body: IndexedStack(
    //         index: _selectedIndex,
    //         children: _pages
    //       ),
    //       bottomNavigationBar: _bottomNavbar());
    //   } 
    //   else {
    //     return Scaffold(
    //       body: Row(
    //         children: [
    //           _sideNavbar(),
    //           const VerticalDivider(thickness: 1, width: 1),
    //           Expanded(
    //             child: IndexedStack(
    //               index: _selectedIndex,
    //               children: _pages
    //             ),
    //           ),
    //         ],
    //       ),
    //     );
    //   }
    // }
  }
}

class BottomNavBar extends StatefulWidget {
  final Widget child;
  const BottomNavBar({super.key, required this.child});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState(child: child);
}

class _BottomNavBarState extends State<BottomNavBar> {
  _BottomNavBarState({Key? key, required this.child});
  Widget? child;
  int currentIndex = 0;
  void changeTab(int index) {
    switch(index){
      case 0:  
        context.go('/');
        break;
      case 1:  
        context.go('/create/diary');
        break;
      default:
        context.go('/search');
        break;
    }
    setState(() {
      currentIndex = index;
    });
  }

  List<BottomNavigationBarItem> get bottomNavbarItems {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home_filled),
        label: 'Home'
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.create_outlined),
        activeIcon: Icon(Icons.create_sharp),
        label: 'Create'
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.search_outlined),
        activeIcon: Icon(Icons.search_sharp),
        label: 'Search'
      ),
    ];
  }

    List<NavigationDestination> get navbarItems {
    return const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_filled),
      label: 'Home',
    ),
     NavigationDestination(
      icon: Icon(Icons.create_outlined),
      selectedIcon: Icon(Icons.create_sharp),
      label: 'Create',
    ),
    NavigationDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search_sharp),
      label: 'Search',
    ),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      // bottomNavigationBar: BottomNavigationBar(
      //   onTap: changeTab,
      //   // backgroundColor: const Color(0xffe0b9f6),
      //   currentIndex: currentIndex,
      //   items: bottomNavbarItems,
      // ),
      bottomNavigationBar: NavigationBar(
        destinations: navbarItems,
        selectedIndex: currentIndex,
        onDestinationSelected: changeTab,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      )
    );
  }

}