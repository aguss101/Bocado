import 'package:flutter/material.dart';
import '../widgets/recipe_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int _selectedTab = 0;
  int _selectedNav = 0;
  final _tabs = ['Para Vos', 'Siguiendo', 'Económicas'];

  final _recipes = [
    RecipeCardData(
      title: 'Salmón a la Plancha con Espárragos',
      author: 'Sarah Jenkins',
      timeMin: '25',
      pricePerServing: '\$4.50 / porción',
      tag: 'Alto Proteína',
      tagColor: const Color(0xFF258CF4),
      imageUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuB4zr7tOV2mH__cQE4GZMyB2i7dK7GMjay_k-jtAe5RhCvb3xmLon8IxIIfsfG65mM4K-BY2vGgSC_BvzWpM6cb0P3kLXe-nXj8u6HBdOBBJ_z7XLStu-acO49c2rwCb3F0hXIhoDHYyyu3OLIJ_Xbf75YPIHNq0Ize366gVBhXVUIqkcy6JdxvAWPN2mXgqu0PaspTagXPLsgbLNrJdyTaFai8QRpgkAazddlJBzZbDhRCOO6wQfj1X-Jz3OzeWih7ICa3XYaXHtog',
      authorAvatarUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBd1B57GeXka4roV2JLxEppb4kkCg3ZWULF-L6_GmhP3UKvoPMSc_hmvHYia4QPb70cKFJa6lxak7yZoo-0mffhWhyJyBP3brO2ZKz-yN6sfiN-FnPxkUB1a3o0-DwnOwLd8o-5ZioWyBFVqrFyRAK6QHC33MeJ9DaaJvTcDlJB39khKNfOdE2rYI0tmn5B1Gt5AVPwALCzxaT8aI3Jo0M-CH5ceyEAvk6TPY5Yhu4jXPZEZDfS4TIlBuMUhVLpbZC36n0vhkYAIZbi',
      calories: 420,
      protein: '32g',
      carbs: '12g',
      fats: '22g',
      likes: 2400,
      comments: 128,
    ),
    RecipeCardData(
      title: 'Bowl de Batata Asada y Kale',
      author: 'Marcus Reed',
      timeMin: '40',
      pricePerServing: '\$2.15 / porción',
      tag: 'Vegano',
      tagColor: const Color(0xFF16A34A),
      imageUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBga40VsN6usNt4WkGRAe2tk0lkqUrNkf5OB8nWSJWK9WDWvyX2JtxIYRvBPPCKNZDa4CZcx5mBi2sC1NC2HAFc3PRdJ4F8QWk895oUXNHU4YU1mSyhQBRrBUieYSDdf4sMv5RS96Lx2TJ_7q2rDpOObKPwLhAM4R2UvpSd2YzFAe770cdlUzb_VU-WIffSix3X-v0azhmDKEz8L4hdLMHiGQzfoQAkOlugpwVYYfZZUi4KUr0OvJhZwNike0_O5JRT_zRkxj6nblWi',
      authorAvatarUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuA-JaH1dBIyud2CCZc7RA_iXzxKrwVP-b-M7kRMW6W4jfFrLBGK_mzCGnmWhICW581oX-KzyYC0-idfeB39oYATpBvgAZjCN0nTL0U7ZdiAOlHCn4FauApGUqoFAsyYVJrZOCU3d9t9ZO7AGcvJZga0Y3r4kqBqQTAiY5gSL_28NDfoqOHKUyTdUWyBh2XGoniYi7U_2O_V3bGbIe_7WoUoE2STaysi8Duw-08unY-pNHugf8XViRnXg1Un4PyNFDn13uN2gCIJZ8d0',
      calories: 380,
      protein: '8g',
      carbs: '64g',
      fats: '14g',
      likes: 1100,
      comments: 45,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(primary, isDark),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(isDark),
          // Tabs
          _buildTabs(primary, isDark),
          // Feed
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _recipes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (_, i) => RecipeCard(data: _recipes[i]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(primary, isDark),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Color primary, bool isDark) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          const Text(
            'Bocado',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            radius: 18,
            backgroundImage: const NetworkImage(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuBeK7yEYiGAbxVjFxO93Vboj94GNbIQtpVNXurnhxlpTG9lygHm9oGKMMV_9_vWaSNTGLV2Kz3SFKtdyJjEg-Fb2nuF0c0pBrVzLS6kdflwLcFt2tjbvAV1tVHGBkIEWAxAK0BS-mXXoDS7t2gPoaTcXQJcAqJB9TnfsTo-zgVqzx3AjwcnpyHS4YKBmrpyqxb1FNl7_wtHuomaguFKy5kWQfRiWG0V7jzoCerUNPUlAI6nlMzrelJYL2UMH6S7DABvPtSFu1ds6rRP',
            ),
            onBackgroundImageError: (_, _) {},
            backgroundColor: const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 20, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar ingredientes, precio o macros...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 16,
              color: Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Icon(Icons.tune, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Filtros',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(Color primary, bool isDark) {
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final isSelected = i == _selectedTab;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                margin: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  _tabs[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : Colors.grey.shade500,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBottomNav(Color primary, bool isDark) {
    final items = [
      {'icon': Icons.home_outlined, 'selectedIcon': Icons.home, 'label': 'Inicio'},
      {'icon': Icons.explore_outlined, 'selectedIcon': Icons.explore, 'label': 'Explorar'},
      {'icon': Icons.bookmark_outline, 'selectedIcon': Icons.bookmark, 'label': 'Guardados'},
      {'icon': Icons.calendar_month_outlined, 'selectedIcon': Icons.calendar_month, 'label': 'Plan'},
      {'icon': Icons.person_outline, 'selectedIcon': Icons.person, 'label': 'Perfil'},
    ];

    return NavigationBar(
      selectedIndex: _selectedNav,
      onDestinationSelected: (i) => setState(() => _selectedNav = i),
      destinations: items
          .asMap()
          .entries
          .map(
            (e) => NavigationDestination(
          icon: Icon(e.value['icon'] as IconData),
          selectedIcon: Icon(e.value['selectedIcon'] as IconData),
          label: e.value['label'] as String,
        ),
      )
          .toList(),
    );
  }
}
