import 'package:cloud_firestore/cloud_firestore.dart';

class ProductsFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add sample jewelry products to Firebase
  Future<void> addSampleProducts() async {
    final products = [
      // Gold Rings
      {
        'name': 'Classic Gold Ring',
        'category': 'Ring',
        'subcategory': 'Classic',
        'weight': 8.5,
        'purity': '22K',
        'makingCharges': 600,
        'goldRate': 5500, // Current rate when added
        'costPrice': 47500, // (8.5 * 5500) + (8.5 * 600)
        'sellingPrice': 52000,
        'profit': 4500,
        'quantity': 12,
        'minStockLevel': 3,
        'size': '16',
        'gender': 'Unisex',
        'description': 'Elegant classic gold ring perfect for daily wear',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Diamond Ring',
        'category': 'Ring',
        'subcategory': 'Diamond',
        'weight': 6.2,
        'purity': '18K',
        'makingCharges': 800,
        'goldRate': 5500,
        'costPrice': 35000,
        'sellingPrice': 45000,
        'profit': 10000,
        'quantity': 5,
        'minStockLevel': 2,
        'size': '14',
        'gender': 'Women',
        'description': 'Beautiful diamond ring with intricate design',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Necklaces
      {
        'name': 'Gold Chain Necklace',
        'category': 'Necklace',
        'subcategory': 'Chain',
        'weight': 25.0,
        'purity': '22K',
        'makingCharges': 400,
        'goldRate': 5500,
        'costPrice': 147500, // (25 * 5500) + (25 * 400)
        'sellingPrice': 155000,
        'profit': 7500,
        'quantity': 8,
        'minStockLevel': 2,
        'length': '18 inches',
        'gender': 'Unisex',
        'description': '22K gold chain necklace, perfect for special occasions',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Traditional Necklace Set',
        'category': 'Necklace',
        'subcategory': 'Traditional',
        'weight': 45.0,
        'purity': '22K',
        'makingCharges': 500,
        'goldRate': 5500,
        'costPrice': 270000, // (45 * 5500) + (45 * 500)
        'sellingPrice': 285000,
        'profit': 15000,
        'quantity': 3,
        'minStockLevel': 1,
        'length': '16 inches',
        'gender': 'Women',
        'description': 'Traditional Indian necklace set with matching earrings',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Earrings
      {
        'name': 'Gold Stud Earrings',
        'category': 'Earrings',
        'subcategory': 'Studs',
        'weight': 3.2,
        'purity': '22K',
        'makingCharges': 700,
        'goldRate': 5500,
        'costPrice': 19840, // (3.2 * 5500) + (3.2 * 700)
        'sellingPrice': 22000,
        'profit': 2160,
        'quantity': 15,
        'minStockLevel': 5,
        'gender': 'Women',
        'description': 'Simple and elegant gold stud earrings',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Jhumka Earrings',
        'category': 'Earrings',
        'subcategory': 'Jhumka',
        'weight': 12.5,
        'purity': '22K',
        'makingCharges': 650,
        'goldRate': 5500,
        'costPrice': 76875, // (12.5 * 5500) + (12.5 * 650)
        'sellingPrice': 82000,
        'profit': 5125,
        'quantity': 6,
        'minStockLevel': 2,
        'gender': 'Women',
        'description': 'Traditional Indian jhumka earrings with intricate work',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Bracelets
      {
        'name': 'Gold Bracelet',
        'category': 'Bracelet',
        'subcategory': 'Classic',
        'weight': 15.0,
        'purity': '18K',
        'makingCharges': 550,
        'goldRate': 5500,
        'costPrice': 90750, // (15 * 5500) + (15 * 550)
        'sellingPrice': 95000,
        'profit': 4250,
        'quantity': 4,
        'minStockLevel': 1,
        'length': '7 inches',
        'gender': 'Women',
        'description': '18K gold bracelet with delicate design',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Bangles
      {
        'name': 'Plain Gold Bangles (Set of 2)',
        'category': 'Bangle',
        'subcategory': 'Plain',
        'weight': 35.0,
        'purity': '22K',
        'makingCharges': 300,
        'goldRate': 5500,
        'costPrice': 203000, // (35 * 5500) + (35 * 300)
        'sellingPrice': 210000,
        'profit': 7000,
        'quantity': 2,
        'minStockLevel': 1,
        'size': 'Medium',
        'gender': 'Women',
        'description': 'Set of 2 plain gold bangles, traditional design',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Pendants
      {
        'name': 'Om Pendant',
        'category': 'Pendant',
        'subcategory': 'Religious',
        'weight': 4.5,
        'purity': '22K',
        'makingCharges': 800,
        'goldRate': 5500,
        'costPrice': 28350, // (4.5 * 5500) + (4.5 * 800)
        'sellingPrice': 31000,
        'profit': 2650,
        'quantity': 10,
        'minStockLevel': 3,
        'gender': 'Unisex',
        'description': 'Religious Om pendant in 22K gold',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Chains
      {
        'name': 'Gold Chain (24 inch)',
        'category': 'Chain',
        'subcategory': 'Regular',
        'weight': 18.5,
        'purity': '22K',
        'makingCharges': 350,
        'goldRate': 5500,
        'costPrice': 108275, // (18.5 * 5500) + (18.5 * 350)
        'sellingPrice': 112000,
        'profit': 3725,
        'quantity': 7,
        'minStockLevel': 2,
        'length': '24 inches',
        'gender': 'Men',
        'description': '22K gold chain for men, 24 inch length',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    // Add each product to Firestore
    for (var product in products) {
      await _db.collection('products').add(product);
    }
  }

  // Get all products
  Stream<QuerySnapshot> getProductsStream() {
    return _db
        .collection('products')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  // Get products by category
  Stream<QuerySnapshot> getProductsByCategory(String category) {
    return _db
        .collection('products')
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  // Get low stock products
  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> lowStockProducts = [];

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if ((data['quantity'] ?? 0) <= (data['minStockLevel'] ?? 0)) {
          lowStockProducts.add({'id': doc.id, ...data});
        }
      }

      return lowStockProducts;
    } catch (e) {
      print('Error getting low stock products: $e');
      return [];
    }
  }

  // Update product quantity
  Future<void> updateProductQuantity(String productId, int newQuantity) async {
    try {
      await _db.collection('products').doc(productId).update({
        'quantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating product quantity: $e');
    }
  }

  // Add new product
  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      await _db.collection('products').add({
        ...productData,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } catch (e) {
      throw Exception('Error adding product: $e');
    }
  }

  // Update product
  Future<void> updateProduct(
      String productId, Map<String, dynamic> productData) async {
    try {
      await _db.collection('products').doc(productId).update({
        ...productData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }

  // Delete product (soft delete)
  Future<void> deleteProduct(String productId) async {
    try {
      await _db.collection('products').doc(productId).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error deleting product: $e');
    }
  }

  // Search products
  Future<List<Map<String, dynamic>>> searchProducts(String searchTerm) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> searchResults = [];

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String name = (data['name'] ?? '').toString().toLowerCase();
        String category = (data['category'] ?? '').toString().toLowerCase();
        String description =
            (data['description'] ?? '').toString().toLowerCase();

        if (name.contains(searchTerm.toLowerCase()) ||
            category.contains(searchTerm.toLowerCase()) ||
            description.contains(searchTerm.toLowerCase())) {
          searchResults.add({'id': doc.id, ...data});
        }
      }

      return searchResults;
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  // Get product categories
  Future<List<String>> getCategories() async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();

      Set<String> categories = {};
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        categories.add(data['category'] ?? '');
      }

      return categories.toList()..sort();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }
}
