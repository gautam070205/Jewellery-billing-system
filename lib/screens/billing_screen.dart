import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jwellery_billing/screens/cart_screens.dart';

import '../services/firestore_service.dart';
import '../widgets/add_customer_dialog.dart';

class BillingScreen extends StatefulWidget {
  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  String? selectedCustomerId;
  TextEditingController searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Title
          Container(
            padding: EdgeInsets.all(24),
            child: Row(
              children: [
                Text(
                  'Billing',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),

          // Steps Indicator
          Container(
            margin: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildStep(0, 'Customer', Icons.person, true),
                _buildStepLine(),
                _buildStep(1, 'Cart', Icons.shopping_cart, false),
                _buildStepLine(),
                _buildStep(2, 'Payment', Icons.payment, false),
                _buildStepLine(),
                _buildStep(3, 'Receipt', Icons.receipt, false),
              ],
            ),
          ),

          SizedBox(height: 32),

          // Search and New Customer
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search customers...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        hintStyle: TextStyle(color: Colors.grey[500]),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _showNewCustomerDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD4AF37),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(Icons.add, size: 20),
                  label: Text('New Customer',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Customer List
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getCustomersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFD4AF37)));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text('No customers found',
                              style: TextStyle(color: Colors.grey[600])),
                          SizedBox(height: 8),
                          TextButton(
                            onPressed: _addDummyData,
                            child: Text('Add Sample Data',
                                style: TextStyle(color: Color(0xFFD4AF37))),
                          ),
                        ],
                      ),
                    );
                  }

                  var customers = snapshot.data!.docs.where((doc) {
                    if (searchController.text.isEmpty) return true;
                    var data = doc.data() as Map<String, dynamic>;
                    String searchTerm = searchController.text.toLowerCase();

                    // Search by name, email, or phone
                    return (data['name']
                                ?.toString()
                                .toLowerCase()
                                .contains(searchTerm) ??
                            false) ||
                        (data['email']
                                ?.toString()
                                .toLowerCase()
                                .contains(searchTerm) ??
                            false) ||
                        (data['phone']
                                ?.toString()
                                .toLowerCase()
                                .contains(searchTerm) ??
                            false);
                  }).toList();

                  // Show "no results found" with add customer option when searching
                  if (customers.isEmpty && searchController.text.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'No customers found for "${searchController.text}"',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Would you like to add this as a new customer?',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 14),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _showNewCustomerDialogWithSearch(
                                searchController.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFD4AF37),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: Icon(Icons.person_add, size: 20),
                            label: Text(
                              'Add "${searchController.text}" as Customer',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      var customer =
                          customers[index].data() as Map<String, dynamic>;
                      var customerId = customers[index].id;
                      bool isSelected = selectedCustomerId == customerId;

                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color(0xFFFFF8DC)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Color(0xFFD4AF37)
                                : Colors.grey[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(0xFFD4AF37),
                            child: Text(
                              _getInitials(customer['name'] ?? ''),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            customer['name'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customer['email'] ?? ''),
                              Text(customer['phone'] ?? ''),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              selectedCustomerId = customerId;
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Continue Button
          Container(
            padding: EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: selectedCustomerId != null
                    ? () {
                        _navigateToCart();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedCustomerId != null
                      ? Color(0xFFD4AF37)
                      : Colors.grey[300],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Continue with Selected Customer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int index, String title, IconData icon, bool isActive) {
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

  String _getInitials(String name) {
    List<String> names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.length == 1 && names[0].length >= 2) {
      return names[0].substring(0, 2).toUpperCase();
    }
    return 'XX';
  }

  Widget _buildCustomerList(List<Map<String, dynamic>> customers) {
    return ListView.builder(
      itemCount: customers.length,
      itemBuilder: (context, index) {
        var customer = customers[index];
        var customerId = customer['id'] ?? 'no-id';
        bool isSelected = selectedCustomerId == customerId;

        print(
            'Building customer: ${customer['name']} with ID: $customerId, isSelected: $isSelected');

        return Container(
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFFFFF8DC) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Color(0xFFD4AF37) : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFFD4AF37),
              child: Text(
                _getInitials(customer['name'] ?? ''),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              customer['name'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer['email'] ?? ''),
                Text(customer['phone'] ?? ''),
              ],
            ),
            onTap: () {
              print(
                  'Customer tapped: ${customer['name']} with ID: $customerId');
              setState(() {
                selectedCustomerId = customerId;
              });
              print('Selected Customer ID set to: $selectedCustomerId');
            },
          ),
        );
      },
    );
  }

  void _showNewCustomerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddCustomerDialog();
      },
    );
  }

  void _showNewCustomerDialogWithSearch(String searchTerm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddCustomerDialog(initialSearchTerm: searchTerm);
      },
    );
  }

  Future<void> _addDummyData() async {
    await _firestoreService.addDummyCustomers();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sample customer data added!')),
    );
  }

  void _navigateToCart() async {
    if (selectedCustomerId != null) {
      try {
        // Get customer details
        DocumentSnapshot customerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(selectedCustomerId)
            .get();

        if (customerDoc.exists) {
          var customerData = customerDoc.data() as Map<String, dynamic>;
          String customerName = customerData['name'] ?? 'Unknown Customer';

          // Navigate to cart screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CartScreen(
                customerId: selectedCustomerId!,
                customerName: customerName,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Customer not found!')),
          );
        }
      } catch (e) {
        print('Navigation error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
