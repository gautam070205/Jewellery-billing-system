import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jwellery_billing/screens/payment_screen.dart';

import '../services/firestore_service.dart';

class CartScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const CartScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with TickerProviderStateMixin {
  List<CartItem> cartItems = [];
  List<Product> shopProducts = [];
  List<Product> filteredProducts = [];
  final FirestoreService _firestoreService = FirestoreService();
  double currentGoldRate = 5500.0;
  double gstRate = 3.0;
  bool isLoadingProducts = true;
  String searchQuery = '';
  String selectedCategory = 'All';
  late TabController _tabController;

  final List<String> categories = [
    'All',
    'Ring',
    'Necklace',
    'Earrings',
    'Bracelet',
    'Chain',
    'Pendant'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadShopProducts();
    _loadCurrentGoldRate();
  }

  void _onTabChanged() {
    if (_tabController.index == 1) {
      // Switched to cart tab - validate all items
      _validateAndFixCart();
    }
  }

  void _validateAndFixCart() {
    print('🔄 VALIDATING ENTIRE CART');
    bool hasChanges = false;
    List<String> fixedItems = [];

    for (int i = cartItems.length - 1; i >= 0; i--) {
      CartItem cartItem = cartItems[i];
      Product? product = shopProducts.firstWhere(
        (p) => p.id == cartItem.productId,
        orElse: () => Product(
            id: '',
            name: '',
            type: '',
            weight: 0,
            purity: '',
            makingCharges: 0,
            quantity: 0),
      );

      if (product.id.isEmpty) {
        // Product not found - remove from cart
        setState(() {
          cartItems.removeAt(i);
        });
        hasChanges = true;
        fixedItems.add('${cartItem.name} - Removed (not found in inventory)');
        print('   ❌ REMOVED: ${cartItem.name} - Product not found');
      } else if (cartItem.quantity > product.quantity) {
        // Quantity exceeds stock - fix it
        int oldQuantity = cartItem.quantity;
        setState(() {
          cartItems[i].quantity = product.quantity;
        });
        hasChanges = true;
        if (product.quantity > 0) {
          fixedItems.add(
              '${cartItem.name} - Reduced from $oldQuantity to ${product.quantity}');
          print(
              '   🔧 FIXED: ${cartItem.name} - Reduced from $oldQuantity to ${product.quantity}');
        } else {
          setState(() {
            cartItems.removeAt(i);
          });
          fixedItems.add('${cartItem.name} - Removed (out of stock)');
          print('   ❌ REMOVED: ${cartItem.name} - Out of stock');
        }
      } else {
        print(
            '   ✅ VALID: ${cartItem.name} - ${cartItem.quantity}/${product.quantity}');
      }
    }

    if (hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🔧 Cart automatically fixed:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...fixedItems.take(3).map(
                  (item) => Text('• $item', style: TextStyle(fontSize: 12))),
              if (fixedItems.length > 3)
                Text('... and ${fixedItems.length - 3} more',
                    style: TextStyle(fontSize: 12)),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Future<void> _loadCurrentGoldRate() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('gold_rates')
          .doc('current')
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double rate = double.tryParse(data['rate'].toString()) ?? 5500.0;
        setState(() {
          currentGoldRate = rate;
        });
        print('Gold rate loaded: ₹$rate/g');
      } else {
        print('No gold rate found, using default: ₹$currentGoldRate/g');
      }
    } catch (e) {
      print('Error loading gold rate: $e');
      // Keep default rate if error
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadShopProducts() async {
    try {
      setState(() => isLoadingProducts = true);

      // Ultra-simple query - just get ALL documents from shop_inventory
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('shop_inventory').get();

      List<Product> products = [];

      print('Found ${snapshot.docs.length} documents in shop_inventory');

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          print(
              'Processing product: ${data['name']} - Available: ${data['available']} - Quantity: ${data['quantity']}');

          // Filter in app - only show available products with quantity > 0
          bool isAvailable = data['available'] == true;
          int quantity = (data['quantity'] ?? 0) as int;

          if (isAvailable && quantity > 0) {
            products.add(Product(
              id: doc.id,
              name: data['name'] ?? 'Unknown Product',
              type: data['type'] ?? 'Unknown',
              weight: double.tryParse(data['weight'].toString()) ?? 0.0,
              purity: data['purity'] ?? '22K',
              makingCharges:
                  double.tryParse(data['makingCharges'].toString()) ?? 0.0,
              quantity: quantity,
              imageUrl: data['imageUrl'] ?? '',
              description: data['description'] ?? '',
              price: double.tryParse(data['price'].toString()) ?? 0.0,
            ));
          }
        } catch (e) {
          print('Error processing document ${doc.id}: $e');
        }
      }

      print('Filtered to ${products.length} available products');

      // Sort in memory
      products.sort((a, b) {
        int typeCompare = a.type.compareTo(b.type);
        if (typeCompare != 0) return typeCompare;
        return a.name.compareTo(b.name);
      });

      setState(() {
        shopProducts = products;
        filteredProducts = products;
        isLoadingProducts = false;
      });

      print('Products loaded successfully!');
    } catch (e) {
      print('Error in _loadShopProducts: $e');
      setState(() => isLoadingProducts = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterProducts() {
    setState(() {
      filteredProducts = shopProducts.where((product) {
        bool matchesSearch =
            product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                product.type.toLowerCase().contains(searchQuery.toLowerCase());
        bool matchesCategory = selectedCategory == 'All' ||
            product.type.toLowerCase() == selectedCategory.toLowerCase();
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: shopProducts.isEmpty
          ? FloatingActionButton.extended(
              onPressed: _initializeDummyData,
              backgroundColor: Color(0xFFD4AF37),
              label: Text('Add Sample Data',
                  style: TextStyle(color: Colors.white)),
              icon: Icon(Icons.add_business, color: Colors.white),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back, color: Color(0xFFD4AF37)),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jewelry Shop - Billing',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              'Customer: ${widget.customerName}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFD4AF37),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                children: [
                                  _buildStep(0, 'Customer', Icons.person, true),
                                  _buildStepLine(),
                                  _buildStep(
                                      1, 'Cart', Icons.shopping_cart, false),
                                  _buildStepLine(),
                                  _buildStep(
                                      2, 'Payment', Icons.payment, false),
                                  _buildStepLine(),
                                  _buildStep(
                                      3, 'Receipt', Icons.receipt, false),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Gold Rate Display
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.trending_up,
                                color: Colors.amber[700], size: 18),
                            SizedBox(width: 8),
                            Text(
                              '₹${currentGoldRate.toStringAsFixed(0)}/g',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[800],
                              ),
                            ),
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: _updateGoldRate,
                              child: Icon(Icons.edit,
                                  size: 16, color: Colors.amber[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Color(0xFFD4AF37),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey[600],
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory, size: 20),
                              SizedBox(width: 8),
                              Text('Shop Inventory'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart, size: 20),
                              SizedBox(width: 4),
                              Text('Cart'),
                              SizedBox(width: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _hasCartStockIssues()
                                      ? Colors.red
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${cartItems.length}',
                                  style: TextStyle(
                                    color: _hasCartStockIssues()
                                        ? Colors.white
                                        : Color(0xFFD4AF37),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInventoryTab(),
                  _buildCartTab(),
                ],
              ),
            ),

            // Cart Summary (always visible when cart has items)
            if (cartItems.isNotEmpty) _buildCartSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int index, String title, IconData icon, bool isActive) {
    if (index == 1) {
      isActive = true;
    }
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? Color(0xFFD4AF37) : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: isActive ? Color(0xFFD4AF37) : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Expanded(
      child: Container(
        height: 2,
        color: Colors.grey[300],
        margin: EdgeInsets.only(bottom: 32),
      ),
    );
  }

  Widget _buildInventoryTab() {
    return Column(
      children: [
        // Search and Filter
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              // Search Bar
              TextField(
                onChanged: (value) {
                  setState(() => searchQuery = value);
                  _filterProducts();
                },
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFFD4AF37)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFD4AF37)),
                  ),
                ),
              ),
              SizedBox(height: 12),
              // Category Filter
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    String category = categories[index];
                    bool isSelected = selectedCategory == category;
                    return Container(
                      margin: EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => selectedCategory = category);
                          _filterProducts();
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: Color(0xFFD4AF37),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Products Grid
        Expanded(
          child: isLoadingProducts
              ? Center(
                  child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
              : filteredProducts.isEmpty
                  ? _buildEmptyInventory()
                  : _buildProductsGrid(),
        ),
      ],
    );
  }

  Widget _buildProductsGrid() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          Product product = filteredProducts[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    bool isInCart = cartItems.any((item) => item.productId == product.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: product.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                            _getProductIcon(product.type),
                            size: 50,
                            color: Color(0xFFD4AF37)),
                      ),
                    )
                  : Icon(_getProductIcon(product.type),
                      size: 50, color: Color(0xFFD4AF37)),
            ),
          ),

          // Product Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${product.weight}g • ${product.purity}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Making: ₹${product.makingCharges}/g',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                  Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '₹${_calculateProductPrice(product).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _addToCart(product),
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isInCart ? Colors.green : Color(0xFFD4AF37),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            isInCart ? Icons.check : Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInventory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadShopProducts,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFD4AF37),
              foregroundColor: Colors.white,
            ),
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartTab() {
    return Column(
      children: [
        // Cart Header with Validation Button
        if (cartItems.isNotEmpty)
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '🛒 Your Cart (${cartItems.length} items)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Check for stock issues and show dialog
                    if (_hasCartStockIssues(showDialog: true)) {
                      // Dialog was shown
                    } else {
                      // No issues found
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('✅ No stock issues found! Cart is valid.'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _hasCartStockIssues() ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: Icon(
                      _hasCartStockIssues()
                          ? Icons.warning
                          : Icons.verified_user,
                      size: 16),
                  label: Text(
                      _hasCartStockIssues() ? 'Check Issues' : 'Validate Cart',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

        // Cart Content
        Expanded(
          child: cartItems.isEmpty ? _buildEmptyCart() : _buildCartList(),
        ),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            'Cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Switch to inventory to add products',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _tabController.animateTo(0),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFD4AF37),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: Icon(Icons.inventory),
            label: Text('Browse Products'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        CartItem item = cartItems[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Product Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getProductIcon(item.type),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${item.weight}g • ${item.purity} • Making: ₹${item.makingCharges}/g',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Quantity Controls
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () =>
                            _updateQuantity(index, item.quantity - 1),
                        icon: Icon(Icons.remove, size: 16),
                        constraints:
                            BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          item.quantity.toString(),
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _updateQuantity(index, item.quantity + 1),
                        icon: Icon(Icons.add, size: 16),
                        constraints:
                            BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 16),

                // Price & Remove
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${_calculateItemTotal(item).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                    SizedBox(height: 4),
                    IconButton(
                      onPressed: () => _removeItem(index),
                      icon: Icon(Icons.delete_outline,
                          color: Colors.red, size: 20),
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartSummary() {
    double subtotal = _calculateSubtotal();
    double gstAmount = subtotal * (gstRate / 100);
    double total = subtotal + gstAmount;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal:', style: TextStyle(fontSize: 16)),
              Text('₹${subtotal.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 16)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GST (${gstRate}%):', style: TextStyle(fontSize: 16)),
              Text('₹${gstAmount.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 16)),
            ],
          ),
          Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4AF37),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _clearCart(),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.red[300]!),
                  ),
                  icon: Icon(Icons.clear_all, color: Colors.red),
                  label:
                      Text('Clear Cart', style: TextStyle(color: Colors.red)),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _proceedToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD4AF37),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(Icons.payment),
                  label: Text(
                    'Proceed to Payment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getProductIcon(String type) {
    switch (type.toLowerCase()) {
      case 'ring':
        return Icons.radio_button_unchecked;
      case 'necklace':
        return Icons.favorite_border;
      case 'earrings':
        return Icons.hearing;
      case 'bracelet':
        return Icons.watch;
      case 'chain':
        return Icons.link;
      case 'pendant':
        return Icons.star_border;
      default:
        return Icons.diamond;
    }
  }

  double _calculateProductPrice(Product product) {
    double goldPrice = product.weight * currentGoldRate;
    double makingCharges = product.weight * product.makingCharges;
    return goldPrice + makingCharges;
  }

  double _calculateItemTotal(CartItem item) {
    double goldPrice = item.weight * currentGoldRate;
    double makingCharges = item.weight * item.makingCharges;
    return (goldPrice + makingCharges) * item.quantity;
  }

  double _calculateSubtotal() {
    return cartItems.fold(0, (sum, item) => sum + _calculateItemTotal(item));
  }

  void _addToCart(Product product) {
    // Check if product is already in cart
    int existingIndex =
        cartItems.indexWhere((item) => item.productId == product.id);

    if (existingIndex != -1) {
      // Update quantity if already in cart
      setState(() {
        cartItems[existingIndex].quantity++;
      });
    } else {
      // Add new item to cart
      setState(() {
        cartItems.add(CartItem(
          productId: product.id,
          name: product.name,
          type: product.type,
          weight: product.weight,
          purity: product.purity,
          makingCharges: product.makingCharges,
          quantity: 1,
        ));
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        backgroundColor: Color(0xFFD4AF37),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeItem(index);
    } else {
      setState(() {
        cartItems[index].quantity = newQuantity;
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      cartItems.removeAt(index);
    });
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Cart'),
        content:
            Text('Are you sure you want to remove all items from the cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => cartItems.clear());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _updateGoldRate() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController rateController =
            TextEditingController(text: currentGoldRate.toString());

        return AlertDialog(
          title: Text('Update Gold Rate'),
          content: TextField(
            controller: rateController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Rate per gram (₹)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  double newRate =
                      double.tryParse(rateController.text) ?? currentGoldRate;

                  // Update in database directly
                  await FirebaseFirestore.instance
                      .collection('gold_rates')
                      .doc('current')
                      .set({
                    'rate': newRate,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  setState(() {
                    currentGoldRate = newRate;
                  });

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Gold rate updated to ₹${currentGoldRate.toStringAsFixed(0)}/g'),
                      backgroundColor: Color(0xFFD4AF37),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating gold rate: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Color(0xFFD4AF37)),
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  bool _hasCartStockIssues({bool showDialog = false}) {
    List<String> stockIssues = [];

    for (CartItem cartItem in cartItems) {
      Product? product = shopProducts.firstWhere(
        (p) => p.id == cartItem.productId,
        orElse: () => Product(
            id: '',
            name: '',
            type: '',
            weight: 0,
            purity: '',
            makingCharges: 0,
            quantity: 0),
      );

      // Check if product not found in inventory
      if (product.id.isEmpty) {
        stockIssues
            .add('${cartItem.name} - Product no longer available in inventory');
        print('❌ Stock Issue: ${cartItem.name} not found in inventory');
      }
      // Check if cart quantity exceeds available stock
      else if (cartItem.quantity > product.quantity) {
        stockIssues.add(
            '${cartItem.name} - Need ${cartItem.quantity}, only ${product.quantity} available');
        print(
            '⚠️ Stock Issue: ${cartItem.name} - Cart: ${cartItem.quantity}, Stock: ${product.quantity}');
      }
    }

    // Show dialog if requested and issues found
    if (showDialog && stockIssues.isNotEmpty) {
      _showStockIssuesDialog(stockIssues);
    }

    bool hasIssues = stockIssues.isNotEmpty;
    if (!hasIssues) {
      print('✅ No stock issues found in cart');
    }

    return hasIssues;
  }

  void _showStockIssuesDialog(List<String> stockIssues) {
    showDialog(
      context: context,
      barrierDismissible: false, // Force user to handle the issues
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '⚠️ Stock Issues Detected!',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your cart contains items that exceed available stock. Please fix these issues before proceeding.',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '📋 Issues Found:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      children: stockIssues
                          .map((issue) => Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 12),
                                margin: EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.remove_circle,
                                        color: Colors.red, size: 16),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        issue,
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: Colors.blue[700], size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '💡 Tip: Use "Auto-Fix Cart" to automatically adjust quantities to available stock.',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close, size: 18),
              label: Text('Close'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _tabController.animateTo(1); // Switch to cart tab
              },
              icon: Icon(Icons.shopping_cart, size: 18),
              label: Text('View Cart'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: BorderSide(color: Colors.orange),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _validateAndFixCart();
              },
              icon: Icon(Icons.auto_fix_high, size: 18, color: Colors.white),
              label: Text(
                'Auto-Fix Cart',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                elevation: 2,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showStockIssueOnAdd(String productName, int available, int requested) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.inventory_2, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text('Stock Limit Reached'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cannot add more $productName',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Available Stock:',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        Text('$available items',
                            style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('You requested:',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        Text('$requested items',
                            style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
            if (available > 0)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _forceSetQuantity(productName, available);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD4AF37)),
                child: Text('Set to Max ($available)',
                    style: TextStyle(color: Colors.white)),
              ),
          ],
        );
      },
    );
  }

  void _forceSetQuantity(String productName, int maxQuantity) {
    // Find the product and set its quantity to max available
    for (int i = 0; i < cartItems.length; i++) {
      if (cartItems[i].name == productName) {
        setState(() {
          cartItems[i].quantity = maxQuantity;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ $productName quantity set to maximum available: $maxQuantity'),
            backgroundColor: Color(0xFFD4AF37),
          ),
        );
        break;
      }
    }
  }

  List<String> _getStockIssues() {
    List<String> issues = [];

    for (CartItem cartItem in cartItems) {
      Product? product = shopProducts.firstWhere(
        (p) => p.id == cartItem.productId,
        orElse: () => Product(
            id: '',
            name: '',
            type: '',
            weight: 0,
            purity: '',
            makingCharges: 0,
            quantity: 0),
      );

      if (product.id.isEmpty) {
        issues.add('${cartItem.name} - Product no longer exists in inventory');
      } else if (cartItem.quantity > product.quantity) {
        issues.add(
            '${cartItem.name} - Need ${cartItem.quantity}, only ${product.quantity} available');
      }
    }

    return issues;
  }

  void _showPaymentBlockedDialog(List<String> stockIssues) {
    showDialog(
      context: context,
      barrierDismissible: false, // CANNOT close by tapping outside
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // CANNOT close with back button
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.block, color: Colors.red, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🚫 Payment Blocked!',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Critical Warning Box
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[400]!, width: 2),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'CANNOT PROCEED TO PAYMENT',
                                style: TextStyle(
                                  color: Colors.red[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your cart contains items that exceed available stock. Payment is blocked until these issues are resolved.',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Issues List
                  Text(
                    '❌ Critical Issues Found:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red[700],
                    ),
                  ),
                  SizedBox(height: 12),

                  Container(
                    constraints: BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        children: stockIssues.asMap().entries.map((entry) {
                          int index = entry.key + 1;
                          String issue = entry.value;
                          return Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            margin: EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$index',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    issue,
                                    style: TextStyle(
                                      color: Colors.red[800],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Solution Box
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb,
                            color: Colors.blue[700], size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '💡 Use "Auto-Fix Cart" to automatically resolve all issues, or manually adjust quantities in your cart.',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Manual Fix Option
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _tabController.animateTo(1); // Go to cart tab
                },
                icon: Icon(Icons.edit, size: 18),
                label: Text('Fix Manually'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: BorderSide(color: Colors.orange),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),

              // Auto-Fix Option (Recommended)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _autoFixCartAndRetryPayment();
                },
                icon: Icon(Icons.auto_fix_high, size: 18, color: Colors.white),
                label: Text(
                  'Auto-Fix & Retry Payment',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  elevation: 3,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _autoFixCartAndRetryPayment() {
    // Show fixing progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16),
              Text(
                '🔧 Auto-fixing cart issues...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Please wait while we adjust quantities',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );

    // Simulate fixing process
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pop(context); // Close progress dialog

      // Actually fix the cart
      _validateAndFixCart();

      // Show success and retry payment
      Future.delayed(Duration(milliseconds: 500), () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Cart fixed successfully! Retrying payment...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Automatically retry payment after fixing
        Future.delayed(Duration(seconds: 1), () {
          _proceedToPayment();
        });
      });
    });
  }

  void _showPaymentDialog() {
    double subtotal = _calculateSubtotal();
    double gstAmount = subtotal * (gstRate / 100);
    double total = subtotal + gstAmount;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.white, size: 18),
            ),
            SizedBox(width: 12),
            Text('✅ Payment Approved - Step 3'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Validation
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🎉 All stock validated! Payment authorized.',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Order Summary
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📋 Order Summary',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Customer: ${widget.customerName}',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('Items: ${cartItems.length}'),
                  Text('Subtotal: ₹${subtotal.toStringAsFixed(0)}'),
                  Text('GST (${gstRate}%): ₹${gstAmount.toStringAsFixed(0)}'),
                  Divider(),
                  Text('Total: ₹${total.toStringAsFixed(0)}',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text('Payment Method:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            DropdownButton<String>(
              value: 'Cash',
              isExpanded: true,
              items: [
                DropdownMenuItem(
                    value: 'Cash',
                    child: Row(
                      children: [
                        Icon(Icons.money, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Cash Payment'),
                      ],
                    )),
                DropdownMenuItem(
                    value: 'Card',
                    child: Row(
                      children: [
                        Icon(Icons.credit_card, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Card Payment'),
                      ],
                    )),
                DropdownMenuItem(
                    value: 'UPI',
                    child: Row(
                      children: [
                        Icon(Icons.qr_code, color: Colors.purple),
                        SizedBox(width: 8),
                        Text('UPI Payment'),
                      ],
                    )),
                DropdownMenuItem(
                    value: 'Bank Transfer',
                    child: Row(
                      children: [
                        Icon(Icons.account_balance, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Bank Transfer'),
                      ],
                    )),
              ],
              onChanged: (value) {
                // Handle payment method selection
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('← Back to Cart'),
          ),
          ElevatedButton.icon(
            onPressed: () => _completeSale(subtotal, gstAmount, total),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD4AF37)),
            icon: Icon(Icons.check_circle, color: Colors.white),
            label: Text('Complete Sale', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _proceedToPayment() async {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cart is empty. Add some products first.')),
      );
      return;
    }

    // Check for stock issues FIRST - this will automatically show dialog if issues found
    List<String> stockIssues = _getStockIssues();

    if (stockIssues.isNotEmpty) {
      // AUTOMATICALLY show dialog when issues detected - payment is BLOCKED
      _showPaymentBlockedDialog(stockIssues);
      return; // STOP here - no payment allowed
    }

    // Only reach here if NO stock issues - navigate to payment screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          customerId: widget.customerId,
          customerName: widget.customerName,
          cartItems: cartItems,
          goldRate: currentGoldRate,
          gstRate: gstRate,
        ),
      ),
    );

    // Handle result from payment screen
    if (result != null && result['success'] == true) {
      // Clear cart after successful payment
      setState(() => cartItems.clear());

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Sale completed successfully! Sale ID: ${result['saleId']}',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Optionally navigate back to customer screen or show receipt
      // Navigator.pop(context);
    }
  }

  Future<void> _initializeDummyData() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFD4AF37)),
                SizedBox(height: 16),
                Text('Setting up sample jewelry data...'),
              ],
            ),
          ),
        ),
      );

      print('Starting to add dummy products...');

      // Add sample jewelry products directly to Firestore
      CollectionReference inventory =
          FirebaseFirestore.instance.collection('shop_inventory');

      final products = [
        {
          'name': 'Classic Gold Ring',
          'type': 'Ring',
          'weight': 3.5,
          'purity': '22K',
          'makingCharges': 800.0,
          'quantity': 10,
          'description': 'Beautiful classic gold ring with intricate design',
          'imageUrl': '',
          'price': 0.0,
          'available': true,
        },
        {
          'name': 'Designer Gold Necklace',
          'type': 'Necklace',
          'weight': 15.2,
          'purity': '22K',
          'makingCharges': 1200.0,
          'quantity': 5,
          'description': 'Elegant designer necklace for special occasions',
          'imageUrl': '',
          'price': 0.0,
          'available': true,
        },
        {
          'name': 'Traditional Gold Earrings',
          'type': 'Earrings',
          'weight': 4.8,
          'purity': '22K',
          'makingCharges': 600.0,
          'quantity': 8,
          'description': 'Traditional style earrings with beautiful patterns',
          'imageUrl': '',
          'price': 0.0,
          'available': true,
        },
      ];

      for (var product in products) {
        await inventory.add({
          ...product,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('Added product: ${product['name']}');
      }

      // Set initial gold rate
      await FirebaseFirestore.instance
          .collection('gold_rates')
          .doc('current')
          .set({
        'rate': 5500.0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Gold rate set successfully');

      // Reload products to show them in the UI
      await _loadShopProducts();

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sample jewelry products added successfully! 🎉'),
          backgroundColor: Color(0xFFD4AF37),
          duration: Duration(seconds: 3),
        ),
      );

      print('Dummy data initialization completed');
    } catch (e) {
      print('Error in _initializeDummyData: $e');
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding sample data: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _completeSale(
      double subtotal, double gstAmount, double total) async {
    try {
      Navigator.pop(context); // Close the dialog

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFD4AF37)),
                SizedBox(height: 16),
                Text('Processing sale...'),
              ],
            ),
          ),
        ),
      );

      // Prepare sale items
      List<Map<String, dynamic>> saleItems = cartItems
          .map((item) => {
                'productId': item.productId,
                'name': item.name,
                'type': item.type,
                'weight': item.weight,
                'purity': item.purity,
                'makingCharges': item.makingCharges,
                'quantity': item.quantity,
                'itemTotal': _calculateItemTotal(item),
              })
          .toList();

      // Create sale record
      String saleId = await _firestoreService.createSale(
        customerId: widget.customerId,
        customerName: widget.customerName,
        items: saleItems,
        subtotal: subtotal,
        gstAmount: gstAmount,
        total: total,
        goldRate: currentGoldRate,
        paymentMethod: 'Cash', // Default, can be made dynamic
      );

      Navigator.pop(context); // Close loading dialog

      // Clear cart
      setState(() => cartItems.clear());

      // Show success
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Sale Completed!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sale ID: $saleId'),
              Text('Customer: ${widget.customerName}'),
              Text('Total: ₹${total.toStringAsFixed(0)}'),
              SizedBox(height: 16),
              Text('✓ Inventory updated'),
              Text('✓ Customer record updated'),
              Text('✓ Sale recorded'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to customer screen
              },
              child: Text('Back to Customers'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // TODO: Navigate to receipt/print screen
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Color(0xFFD4AF37)),
              child:
                  Text('Print Receipt', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing sale: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Product Model for Shop Inventory
class Product {
  final String id;
  final String name;
  final String type;
  final double weight;
  final String purity;
  final double makingCharges;
  final int quantity;
  final String imageUrl;
  final String description;
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.type,
    required this.weight,
    required this.purity,
    required this.makingCharges,
    required this.quantity,
    this.imageUrl = '',
    this.description = '',
    this.price = 0.0,
  });
}
