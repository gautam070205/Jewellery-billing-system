import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class AddCustomerDialog extends StatefulWidget {
  final String? initialSearchTerm;

  const AddCustomerDialog({super.key, this.initialSearchTerm});

  @override
  _AddCustomerDialogState createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _autoFillFromSearchTerm();
  }

  void _autoFillFromSearchTerm() {
    if (widget.initialSearchTerm != null &&
        widget.initialSearchTerm!.isNotEmpty) {
      String searchTerm = widget.initialSearchTerm!;

      // Check if it looks like an email
      if (searchTerm.contains('@') && searchTerm.contains('.')) {
        emailController.text = searchTerm;
      }
      // Check if it looks like a phone number (contains only digits, spaces, +, -, (, ))
      else if (RegExp(r'^[\d\s\+\-\(\)]+$').hasMatch(searchTerm)) {
        phoneController.text = searchTerm;
      }
      // Otherwise assume it's a name
      else {
        nameController.text = searchTerm;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(0xFFD4AF37),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Customer',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.initialSearchTerm != null
                            ? 'Adding "${widget.initialSearchTerm}" as new customer'
                            : 'Enter customer details below',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.initialSearchTerm != null
                              ? Color(0xFFD4AF37)
                              : Colors.grey[600],
                          fontWeight: widget.initialSearchTerm != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                ),
              ],
            ),

            SizedBox(height: 32),

            // Auto-fill notification
            if (widget.initialSearchTerm != null &&
                widget.initialSearchTerm!.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Color(0xFFFFF8DC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFD4AF37)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        color: Color(0xFFD4AF37), size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getAutoFillMessage(),
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Form Fields
            _buildDialogTextField(
              controller: nameController,
              label: 'Full Name',
              icon: Icons.person,
              required: true,
            ),
            SizedBox(height: 20),

            _buildDialogTextField(
              controller: emailController,
              label: 'Email Address',
              icon: Icons.email,
              onChanged: (value) async {
                if (value.isNotEmpty) {
                  await _checkExistingCustomerByEmail(value);
                }
              },
            ),
            SizedBox(height: 20),

            _buildDialogTextField(
              controller: phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              onChanged: (value) async {
                if (value.isNotEmpty) {
                  await _checkExistingCustomerByPhone(value);
                }
              },
            ),

            SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (nameController.text.isNotEmpty && !isLoading)
                        ? () async {
                            await _saveCustomer();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD4AF37),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Add Customer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            onChanged: (value) {
              setState(() {}); // Update button state
              if (onChanged != null) onChanged(value);
            },
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Color(0xFFD4AF37), size: 20),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: 'Enter $label',
              hintStyle: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ),
      ],
    );
  }

  String _getAutoFillMessage() {
    if (widget.initialSearchTerm == null) return '';

    String searchTerm = widget.initialSearchTerm!;

    if (searchTerm.contains('@') && searchTerm.contains('.')) {
      return 'Email field auto-filled from your search';
    } else if (RegExp(r'^[\d\s\+\-\(\)]+$').hasMatch(searchTerm)) {
      return 'Phone field auto-filled from your search';
    } else {
      return 'Name field auto-filled from your search';
    }
  }

  Future<void> _checkExistingCustomerByEmail(String email) async {
    final customer = await _firestoreService.getCustomerByEmail(email);
    if (customer != null) {
      setState(() {
        nameController.text = customer['name'] ?? '';
        phoneController.text = customer['phone'] ?? '';
      });
      _showExistingCustomerSnackBar('Email');
    }
  }

  Future<void> _checkExistingCustomerByPhone(String phone) async {
    final customer = await _firestoreService.getCustomerByPhone(phone);
    if (customer != null) {
      setState(() {
        nameController.text = customer['name'] ?? '';
        emailController.text = customer['email'] ?? '';
      });
      _showExistingCustomerSnackBar('Phone');
    }
  }

  void _showExistingCustomerSnackBar(String fieldType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$fieldType already exists! Information auto-filled.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveCustomer() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _firestoreService.saveCustomer(
        nameController.text.trim(),
        emailController.text.trim(),
        phoneController.text.trim(),
      );

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Customer saved successfully!'),
            ],
          ),
          backgroundColor: Color(0xFFD4AF37),
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
              Expanded(child: Text('Error saving customer: $e')),
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

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
