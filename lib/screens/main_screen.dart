import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'pedidos_screen.dart';
import 'productos_screen.dart';
import 'clientes_screen.dart';
import 'profile_screen.dart';
import 'create_admin_screen.dart';

/// Estructura principal de navegación de la app.
/// En web/escritorio usa NavigationRail lateral; en móvil usa Drawer.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.storage});

  final StorageService storage;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<_NavItem> _items = [
    _NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined),
    _NavItem(label: 'Pedidos', icon: Icons.receipt_long_outlined),
    _NavItem(label: 'Productos', icon: Icons.inventory_2_outlined),
    _NavItem(label: 'Clientes', icon: Icons.people_outline),
  ];

  List<Widget> get _pages => [
        DashboardScreen(storage: widget.storage),
        const PedidosScreen(),
        const ProductosScreen(),
        const ClientesScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(_items[_selectedIndex].label),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: AppColors.yellow),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(storage: widget.storage),
                  ),
                );
              } else if (value == 'create_admin') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateAdminScreen(),
                  ),
                );
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'info',
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.storage.nombre ?? 'Administrador',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    Text(
                      widget.storage.correo ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray,
                      ),
                    ),
                    const Divider(),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: AppColors.red),
                    SizedBox(width: 8),
                    Text('Mi Perfil'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'create_admin',
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: AppColors.yellowDark),
                    SizedBox(width: 8),
                    Text('Crear Administrador'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.red),
                    SizedBox(width: 8),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: isWide ? _buildWideLayout() : _buildMobileLayout(),
    );
  }

  /// Layout con NavigationRail lateral (web/escritorio).
  Widget _buildWideLayout() {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          backgroundColor: AppColors.black,
          indicatorColor: AppColors.red,
          selectedIconTheme: const IconThemeData(color: AppColors.white),
          unselectedIconTheme: IconThemeData(
            color: AppColors.white.withValues(alpha: 0.6),
          ),
          selectedLabelTextStyle: const TextStyle(
            color: AppColors.yellow,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelTextStyle: TextStyle(
            color: AppColors.white.withValues(alpha: 0.6),
          ),
          labelType: NavigationRailLabelType.all,
          leading: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront, color: AppColors.white),
            ),
          ),
          destinations: _items
              .map(
                (item) => NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.label),
                ),
              )
              .toList(),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(child: _pages[_selectedIndex]),
      ],
    );
  }

  /// Layout con Drawer (móvil).
  Widget _buildMobileLayout() {
    return Scaffold(
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.red),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.storefront,
                    color: AppColors.white, size: 36),
                const SizedBox(height: 8),
                Text(
                  widget.storage.nombre ?? 'Administrador',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.storage.correo ?? '',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ..._items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == _selectedIndex;
            return ListTile(
              leading: Icon(
                item.icon,
                color: isSelected ? AppColors.yellow : AppColors.white,
              ),
              title: Text(
                item.label,
                style: TextStyle(
                  color: isSelected ? AppColors.yellow : AppColors.white,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onTap: () {
                setState(() => _selectedIndex = index);
                Navigator.of(context).pop();
              },
            );
          }),
          const Divider(color: AppColors.gray),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.red),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.white),
            ),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await widget.storage.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon});
  final String label;
  final IconData icon;
}
