import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection references for easy access
  CollectionReference get shopInventory => _db.collection('shop_inventory');
  CollectionReference get customers => _db.collection('customers');
  CollectionReference get sales => _db.collection('sales');
  CollectionReference get goldRates => _db.collection('gold_rates');

  // ========== CUSTOMER MANAGEMENT ==========

  // Get customers stream for real-time updates
  Stream<QuerySnapshot> getCustomersStream() {
    try {
      return _db.collection('customers').snapshots();
    } catch (e) {
      print('Error getting customers stream: $e');
      return Stream.empty();
    }
  }

  // Get customer by email
  Future<Map<String, dynamic>?> getCustomerByEmail(String email) async {
    try {
      QuerySnapshot emailQuery = await _db
          .collection('customers')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        return emailQuery.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting customer by email: $e');
      return null;
    }
  }

  // Get customer by phone
  Future<Map<String, dynamic>?> getCustomerByPhone(String phone) async {
    try {
      QuerySnapshot phoneQuery = await _db
          .collection('customers')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (phoneQuery.docs.isNotEmpty) {
        return phoneQuery.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting customer by phone: $e');
      return null;
    }
  }

  // Save customer (add new or update existing)
  Future<String> saveCustomer(String name, String email, String phone,
      {String address = ''}) async {
    try {
      // Check if customer already exists by email or phone
      QuerySnapshot existingQuery = await _db
          .collection('customers')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingQuery.docs.isEmpty && phone.isNotEmpty) {
        existingQuery = await _db
            .collection('customers')
            .where('phone', isEqualTo: phone)
            .limit(1)
            .get();
      }

      if (existingQuery.docs.isNotEmpty) {
        // Update existing customer
        String customerId = existingQuery.docs.first.id;
        await _db.collection('customers').doc(customerId).update({
          'name': name,
          'email': email,
          'phone': phone,
          'address': address,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return customerId;
      } else {
        // Add new customer
        DocumentReference docRef = await _db.collection('customers').add({
          'name': name,
          'email': email,
          'phone': phone,
          'address': address,
          'totalPurchases': 0.0,
          'lastPurchase': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return docRef.id;
      }
    } catch (e) {
      throw Exception('Error saving customer: $e');
    }
  }

  // Get all customers
  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    try {
      QuerySnapshot snapshot = await _db.collection('customers').get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error getting all customers: $e');
      return [];
    }
  }

  // Get customers stream (alternative method)
  Stream<QuerySnapshot> getCustomers() {
    return customers.snapshots();
  }

  // Delete customer
  Future<void> deleteCustomer(String customerId) async {
    try {
      await _db.collection('customers').doc(customerId).delete();
    } catch (e) {
      throw Exception('Error deleting customer: $e');
    }
  }

  // Search customers (simplified - get all and filter in app)
  Future<List<Map<String, dynamic>>> searchCustomers(String searchTerm) async {
    try {
      QuerySnapshot snapshot = await _db.collection('customers').get();

      List<Map<String, dynamic>> allCustomers = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      // Filter in app
      return allCustomers.where((customer) {
        String name = (customer['name'] ?? '').toString().toLowerCase();
        String phone = (customer['phone'] ?? '').toString().toLowerCase();
        String email = (customer['email'] ?? '').toString().toLowerCase();
        String search = searchTerm.toLowerCase();

        return name.contains(search) ||
            phone.contains(search) ||
            email.contains(search);
      }).toList();
    } catch (e) {
      print('Error searching customers: $e');
      return [];
    }
  }

  // ========== JEWELRY SHOP INVENTORY MANAGEMENT ==========

  // Add a new product to shop inventory
  Future<String> addProduct({
    required String name,
    required String type,
    required double weight,
    required String purity,
    required double makingCharges,
    required int quantity,
    String imageUrl = '',
    String description = '',
    double price = 0.0,
  }) async {
    try {
      DocumentReference docRef = await shopInventory.add({
        'name': name,
        'type': type,
        'weight': weight,
        'purity': purity,
        'makingCharges': makingCharges,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'description': description,
        'price': price,
        'available': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // Get all available products (no complex queries)
  Stream<QuerySnapshot> getAvailableProducts() {
    return shopInventory.snapshots();
  }

  // Get products by category (no complex queries)
  Stream<QuerySnapshot> getProductsByCategory(String category) {
    return shopInventory.snapshots();
  }

  // Update product quantity (when sold)
  Future<void> updateProductQuantity(String productId, int newQuantity) async {
    try {
      await shopInventory.doc(productId).update({
        'quantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
        'available': newQuantity > 0,
      });
    } catch (e) {
      throw Exception('Failed to update product quantity: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await shopInventory.doc(productId).update({
        'available': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Add dummy customer data
  Future<void> addDummyCustomers() async {
    final customers = [];

    for (var customer in customers) {
      await _db.collection('customers').add({
        ...customer,
        'totalPurchases': 0.0,
        'lastPurchase': null,
        'address': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Add dummy jewelry products
  Future<void> addDummyProducts() async {
    final products = [
      {
        'name': 'Classic Gold Ring',
        'type': 'Ring',
        'weight': 3.5,
        'purity': '22K',
        'makingCharges': 800.0,
        'quantity': 10,
        'description': 'Beautiful classic gold ring with intricate design',
      },
      {
        'name': 'Designer Gold Necklace',
        'type': 'Necklace',
        'weight': 15.2,
        'purity': '22K',
        'makingCharges': 1200.0,
        'quantity': 5,
        'description': 'Elegant designer necklace for special occasions',
      },
      {
        'name': 'Traditional Gold Earrings',
        'type': 'Earrings',
        'weight': 4.8,
        'purity': '22K',
        'makingCharges': 600.0,
        'quantity': 8,
        'description': 'Traditional style earrings with beautiful patterns',
      },
      {
        'name': 'Elegant Gold Bracelet',
        'type': 'Bracelet',
        'weight': 8.3,
        'purity': '18K',
        'makingCharges': 900.0,
        'quantity': 6,
        'description': 'Stylish gold bracelet for everyday wear',
      },
      {
        'name': 'Gold Chain 20 inch',
        'type': 'Chain',
        'weight': 12.7,
        'purity': '22K',
        'makingCharges': 1000.0,
        'quantity': 4,
        'description': '20 inch gold chain with secure clasp',
      },
      {
        'name': 'Heart Shaped Pendant',
        'type': 'Pendant',
        'weight': 2.1,
        'purity': '22K',
        'makingCharges': 500.0,
        'quantity': 12,
        'description': 'Beautiful heart shaped pendant for necklaces',
      },
    ];

    for (var product in products) {
      await shopInventory.add({
        ...product,
        'imageUrl': '',
        'price': 0.0,
        'available': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ========== SALES & BILLING MANAGEMENT ==========

  // Create a sale record
  Future<String> createSale({
    required String customerId,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double gstAmount,
    required double total,
    required double goldRate,
    String paymentMethod = 'Cash',
  }) async {
    try {
      // Create sale record
      DocumentReference saleRef = await sales.add({
        'customerId': customerId,
        'customerName': customerName,
        'items': items,
        'subtotal': subtotal,
        'gstAmount': gstAmount,
        'total': total,
        'goldRate': goldRate,
        'paymentMethod': paymentMethod,
        'saleDate': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      // Update customer's total purchases
      await customers.doc(customerId).update({
        'totalPurchases': FieldValue.increment(total),
        'lastPurchase': FieldValue.serverTimestamp(),
      });

      // Update product quantities
      for (Map<String, dynamic> item in items) {
        String productId = item['productId'];
        int quantity = item['quantity'];

        DocumentSnapshot productDoc = await shopInventory.doc(productId).get();
        if (productDoc.exists) {
          Map<String, dynamic> productData =
              productDoc.data() as Map<String, dynamic>;
          int currentQuantity = productData['quantity'] ?? 0;
          int newQuantity = currentQuantity - quantity;

          await updateProductQuantity(productId, newQuantity);
        }
      }

      return saleRef.id;
    } catch (e) {
      throw Exception('Failed to create sale: $e');
    }
  }

  // Get sales history (no complex queries)
  Stream<QuerySnapshot> getSalesHistory() {
    return sales.snapshots();
  }

  // Get customer's purchase history (no complex queries)
  Future<QuerySnapshot> getCustomerPurchases(String customerId) async {
    try {
      return await sales.where('customerId', isEqualTo: customerId).get();
    } catch (e) {
      throw Exception('Failed to get customer purchases: $e');
    }
  }

  // ========== GOLD RATE MANAGEMENT ==========

  // Update or create gold rate
  Future<void> updateGoldRate(double rate) async {
    try {
      await goldRates.doc('current').set({
        'rate': rate,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update gold rate: $e');
    }
  }

  // Get current gold rate
  Future<double> getCurrentGoldRate() async {
    try {
      DocumentSnapshot doc = await goldRates.doc('current').get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return (data['rate'] ?? 5500.0).toDouble();
      }
      return 5500.0; // Default rate
    } catch (e) {
      return 5500.0; // Default rate on error
    }
  }

  // ========== REPORTS & ANALYTICS ==========

  // Get daily sales report (simplified)
  Future<Map<String, dynamic>> getDailySalesReport(DateTime date) async {
    try {
      // Get all sales and filter in app
      QuerySnapshot salesSnapshot = await sales.get();

      DateTime startOfDay = DateTime(date.year, date.month, date.day);
      DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      double totalSales = 0.0;
      int totalTransactions = 0;
      int totalItems = 0;

      for (QueryDocumentSnapshot doc in salesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Check if sale is within the target date
        Timestamp? saleTimestamp = data['saleDate'] as Timestamp?;
        if (saleTimestamp != null) {
          DateTime saleDate = saleTimestamp.toDate();
          if (saleDate.isAfter(startOfDay) && saleDate.isBefore(endOfDay)) {
            totalTransactions++;
            totalSales += (data['total'] ?? 0.0).toDouble();

            List<dynamic> items = data['items'] ?? [];
            for (dynamic item in items) {
              totalItems += (item['quantity'] ?? 0) as int;
            }
          }
        }
      }

      return {
        'totalSales': totalSales,
        'totalTransactions': totalTransactions,
        'totalItems': totalItems,
        'averageTransaction':
            totalTransactions > 0 ? totalSales / totalTransactions : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get daily sales report: $e');
    }
  }

  // Get low stock products (no complex queries)
  Future<QuerySnapshot> getLowStockProducts({int threshold = 5}) async {
    try {
      return await shopInventory.get();
    } catch (e) {
      throw Exception('Failed to get low stock products: $e');
    }
  }

  // Get popular products (no complex queries)
  Future<List<Map<String, dynamic>>> getPopularProducts(
      {int limit = 10}) async {
    try {
      QuerySnapshot salesSnapshot = await sales.get();

      Map<String, Map<String, dynamic>> productSales = {};

      for (QueryDocumentSnapshot doc in salesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> items = data['items'] ?? [];

        for (dynamic item in items) {
          String productId = item['productId'] ?? '';
          String productName = item['name'] ?? '';
          int quantity = (item['quantity'] ?? 0) as int;

          if (productSales.containsKey(productId)) {
            productSales[productId]!['totalSold'] += quantity;
          } else {
            productSales[productId] = {
              'productId': productId,
              'name': productName,
              'totalSold': quantity,
            };
          }
        }
      }

      List<Map<String, dynamic>> sortedProducts = productSales.values.toList();
      sortedProducts.sort((a, b) => b['totalSold'].compareTo(a['totalSold']));

      return sortedProducts.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get popular products: $e');
    }
  }

  // ========== UTILITY METHODS ==========

  // Initialize database with dummy data
  Future<void> initializeDummyData() async {
    try {
      // Add dummy customers
      await addDummyCustomers();
      print('Dummy customers added successfully');

      // Add dummy products
      await addDummyProducts();
      print('Dummy products added successfully');

      // Set initial gold rate
      await updateGoldRate(5500.0);
      print('Initial gold rate set successfully');
    } catch (e) {
      print('Error initializing dummy data: $e');
    }
  }

  // Clear all data (use with caution)
  Future<void> clearAllData() async {
    try {
      // Clear customers
      QuerySnapshot customersSnapshot = await customers.get();
      for (DocumentSnapshot doc in customersSnapshot.docs) {
        await doc.reference.delete();
      }

      // Clear products
      QuerySnapshot productsSnapshot = await shopInventory.get();
      for (DocumentSnapshot doc in productsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Clear sales
      QuerySnapshot salesSnapshot = await sales.get();
      for (DocumentSnapshot doc in salesSnapshot.docs) {
        await doc.reference.delete();
      }

      print('All data cleared successfully');
    } catch (e) {
      print('Error clearing data: $e');
    }
  }
}
