import 'package:flutter/material.dart';
import 'package:jwellery_billing/screens/payment_screen.dart';

class AddProductDialog extends StatefulWidget {
  final Function(CartItem) onProductAdded;

  const AddProductDialog({super.key, required this.onProductAdded});

  @override
  _AddProductDialogState createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final nameController = TextEditingController();
  final weightController = TextEditingController();
  final makingChargesController = TextEditingController();

  String selectedType = 'Ring';
  String selectedPurity = '22K';

  final List<String> productTypes = [
    'Ring',
    'Necklace',
    'Earrings',
    'Bracelet',
    'Chain',
    'Bangle',
    'Pendant',
    'Anklet'
  ];

  final List<String> purityOptions = ['24K', '22K', '21K', '18K', '14K', '10K'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
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
                    Icons.diamond,
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
                        'Add Jewelry Product',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Enter product details for billing',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
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

            // Product Type & Name Row
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField(
                    label: 'Product Type',
                    value: selectedType,
                    items: productTypes,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                        if (nameController.text.isEmpty) {
                          nameController.text = value;
                        }
                      });
                    },
                    icon: Icons.category,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: nameController,
                    label: 'Product Name',
                    icon: Icons.label,
                    required: true,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Weight & Purity Row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: weightController,
                    label: 'Weight (grams)',
                    icon: Icons.scale,
                    required: true,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildDropdownField(
                    label: 'Gold Purity',
                    value: selectedPurity,
                    items: purityOptions,
                    onChanged: (value) {
                      setState(() {
                        selectedPurity = value!;
                      });
                    },
                    icon: Icons.verified,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Making Charges
            _buildTextField(
              controller: makingChargesController,
              label: 'Making Charges (₹ per gram)',
              icon: Icons.build,
              required: true,
              keyboardType: TextInputType.number,
            ),

            SizedBox(height: 32),

            // Preview Section
            if (_isFormValid()) _buildPreview(),

            SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
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
                    onPressed: _isFormValid() ? _addProduct : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD4AF37),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Add to Cart',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
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
            keyboardType: keyboardType,
            onChanged: (value) => setState(() {}),
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

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
          child: DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Color(0xFFD4AF37), size: 20),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    double weight = double.tryParse(weightController.text) ?? 0;
    double makingCharges = double.tryParse(makingChargesController.text) ?? 0;
    double goldRate = 5500; // This should come from the cart screen

    double goldPrice = weight * goldRate;
    double totalMakingCharges = weight * makingCharges;
    double itemTotal = goldPrice + totalMakingCharges;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFFF8DC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFD4AF37)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, color: Color(0xFFD4AF37), size: 20),
              SizedBox(width: 8),
              Text(
                'Price Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gold Cost (${weight}g × ₹$goldRate):'),
              Text('₹${goldPrice.toStringAsFixed(0)}'),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Making Charges (${weight}g × ₹$makingCharges):'),
              Text('₹${totalMakingCharges.toStringAsFixed(0)}'),
            ],
          ),
          Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item Total:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${itemTotal.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4AF37),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isFormValid() {
    return nameController.text.isNotEmpty &&
        weightController.text.isNotEmpty &&
        makingChargesController.text.isNotEmpty &&
        double.tryParse(weightController.text) != null &&
        double.tryParse(makingChargesController.text) != null;
  }

  void _addProduct() {
    CartItem newItem = CartItem(
      name: nameController.text,
      type: selectedType,
      weight: double.parse(weightController.text),
      purity: selectedPurity,
      makingCharges: double.parse(makingChargesController.text),
      productId: '',
    );

    widget.onProductAdded(newItem);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('${newItem.name} added to cart!'),
          ],
        ),
        backgroundColor: Color(0xFFD4AF37),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    weightController.dispose();
    makingChargesController.dispose();
    super.dispose();
  }
}
