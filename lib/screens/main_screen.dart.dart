import 'package:flutter/material.dart';

import 'billing_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 2; // Billing is selected

  final List<String> menuItems = [
    'Dashboard',
    'Add Product',
    'Billing',
    'Settings'
  ];

  final List<IconData> menuIcons = [
    Icons.dashboard,
    Icons.add_circle_outline,
    Icons.receipt_long,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            color: Colors.white,
            child: Column(
              children: [
                // Logo Section
                Container(
                  height: 80,
                  color: Color(0xFFD4AF37), // Gold color
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.build, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Jewelry Inventory',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Menu Items
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: List.generate(menuItems.length, (index) {
                        bool isSelected = index == selectedIndex;
                        return Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Material(
                            color: isSelected
                                ? Color(0xFFFFF8DC)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                setState(() {
                                  selectedIndex = index;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Icon(
                                      menuIcons[index],
                                      color: isSelected
                                          ? Color(0xFFD4AF37)
                                          : Colors.grey[600],
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      menuItems[index],
                                      style: TextStyle(
                                        color: isSelected
                                            ? Color(0xFFD4AF37)
                                            : Colors.grey[700],
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                // Version
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Version 1.0',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 60,
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        'Jewelry Inventory Management',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.grey[600]),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                // Content Area
                Expanded(
                  child: selectedIndex == 2
                      ? BillingScreen()
                      : selectedIndex == 4
                          ? _buildOtherScreens()
                          : _buildOtherScreens(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherScreens() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            menuIcons[selectedIndex],
            size: 64,
            color: Color(0xFFD4AF37),
          ),
          SizedBox(height: 16),
          Text(
            '${menuItems[selectedIndex]} Screen',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This screen is under development',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
