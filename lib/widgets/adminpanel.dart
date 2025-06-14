// Add this to your main_screen.dart or create a separate admin screen

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jwellery_billing/services/product_firestore_service.dart';

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final ProductsFirestoreService _productsService = ProductsFirestoreService();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        backgroundColor: Color(0xFFD4AF37),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 100,
              color: Color(0xFFD4AF37),
            ),
            SizedBox(height: 30),
            Text(
              'Product Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Add sample jewelry products to Firebase',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 40),

            // Add Sample Products Button
            Container(
              width: 300,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _addSampleProducts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFD4AF37),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.add_business, size: 24),
                label: Text(
                  isLoading ? 'Adding Products...' : 'Add Sample Products',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // View Products Button
            Container(
              width: 300,
              child: OutlinedButton.icon(
                onPressed: _viewProducts,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Color(0xFFD4AF37)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(Icons.inventory, color: Color(0xFFD4AF37)),
                label: Text(
                  'View Products',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD4AF37),
                  ),
                ),
              ),
            ),

            SizedBox(height: 40),

            // Firebase Console Link
            Text(
              'You can also add products manually in:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'Firebase Console → Firestore → products collection',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSampleProducts() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _productsService.addSampleProducts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Sample products added successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Error adding products: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _viewProducts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductsListScreen(),
      ),
    );
  }
}

// Products List Screen to view added products
class ProductsListScreen extends StatelessWidget {
  final ProductsFirestoreService _productsService = ProductsFirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products Inventory'),
        backgroundColor: Color(0xFFD4AF37),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _productsService.getProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text('No products found',
                      style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 8),
                  Text('Add some products to get started',
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }

          var products = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              var product = products[index].data() as Map<String, dynamic>;

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getProductIcon(product['category'] ?? ''),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    product['name'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(
                          '${product['category']} • ${product['weight']}g • ${product['purity']}'),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Text('Stock: ${product['quantity']}',
                              style: TextStyle(
                                  color: (product['quantity'] ?? 0) <=
                                          (product['minStockLevel'] ?? 0)
                                      ? Colors.red
                                      : Colors.green)),
                          SizedBox(width: 16),
                          Text(
                              '₹${(product['sellingPrice'] ?? 0).toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD4AF37))),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getProductIcon(String category) {
    switch (category.toLowerCase()) {
      case 'ring':
        return Icons.radio_button_unchecked;
      case 'necklace':
        return Icons.favorite_border;
      case 'earrings':
        return Icons.hearing;
      case 'bracelet':
      case 'bangle':
        return Icons.watch;
      case 'chain':
        return Icons.link;
      case 'pendant':
        return Icons.star_border;
      default:
        return Icons.diamond;
    }
  }
}
