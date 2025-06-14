import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jwellery_billing/screens/recipt_screen.dart';

import '../services/firestore_service.dart';

class PaymentScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final List<CartItem> cartItems;
  final double goldRate;
  final double gstRate;

  const PaymentScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.cartItems,
    required this.goldRate,
    required this.gstRate,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();

  String selectedPaymentMethod = 'Cash';
  String selectedUPIMethod = '';
  String selectedBankMethod = '';
  bool isProcessingPayment = false;
  bool paymentValidated = false;

  // Form controllers for card payment
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _successController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _successAnimation;

  final List<PaymentMethod> paymentMethods = [
    PaymentMethod(
      name: 'Cash',
      icon: Icons.money,
      gradient: [Color(0xFF4CAF50), Color(0xFF45A049)],
      description: 'Instant cash payment',
    ),
    PaymentMethod(
      name: 'Card',
      icon: Icons.credit_card,
      gradient: [Color(0xFF2196F3), Color(0xFF1976D2)],
      description: 'Debit/Credit card payment',
    ),
    PaymentMethod(
      name: 'UPI',
      icon: Icons.qr_code_scanner,
      gradient: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
      description: 'UPI payment via apps',
    ),
    PaymentMethod(
      name: 'Bank Transfer',
      icon: Icons.account_balance,
      gradient: [Color(0xFFFF9800), Color(0xFFF57C00)],
      description: 'RTGS/NEFT transfer',
    ),
  ];

  final List<UPIMethod> upiMethods = [
    UPIMethod(
      name: 'GooglePay',
      displayName: 'Google Pay',
      icon: Icons.g_mobiledata,
      color: Color(0xFF4285F4),
    ),
    UPIMethod(
      name: 'PhonePe',
      displayName: 'PhonePe',
      icon: Icons.phone_android,
      color: Color(0xFF5F259F),
    ),
    UPIMethod(
      name: 'Paytm',
      displayName: 'Paytm',
      icon: Icons.payment,
      color: Color(0xFF00BAF2),
    ),
    UPIMethod(
      name: 'BHIM',
      displayName: 'BHIM UPI',
      icon: Icons.account_balance,
      color: Color(0xFF1976D2),
    ),
  ];

  final List<BankMethod> bankMethods = [
    BankMethod(
      name: 'RTGS',
      displayName: 'RTGS Transfer',
      icon: Icons.swap_horiz,
      description: 'Real Time Gross Settlement',
      color: Color(0xFF1976D2),
    ),
    BankMethod(
      name: 'NEFT',
      displayName: 'NEFT Transfer',
      icon: Icons.account_balance_wallet,
      description: 'National Electronic Fund Transfer',
      color: Color(0xFF388E3C),
    ),
    BankMethod(
      name: 'IMPS',
      displayName: 'IMPS Transfer',
      icon: Icons.flash_on,
      description: 'Immediate Payment Service',
      color: Color(0xFFFF9800),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startIntroAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _successController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _startIntroAnimations() async {
    await Future.delayed(Duration(milliseconds: 100));
    _fadeController.forward();
    await Future.delayed(Duration(milliseconds: 200));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  double get subtotal {
    return widget.cartItems
        .fold(0, (sum, item) => sum + _calculateItemTotal(item));
  }

  double get gstAmount {
    return subtotal * (widget.gstRate / 100);
  }

  double get total {
    return subtotal + gstAmount;
  }

  double _calculateItemTotal(CartItem item) {
    double goldPrice = item.weight * widget.goldRate;
    double makingCharges = item.weight * item.makingCharges;
    return (goldPrice + makingCharges) * item.quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderSummaryCard(),
                        SizedBox(height: 16),
                        _buildPaymentMethodCard(),
                        SizedBox(height: 16),
                        // Conditional content based on payment method
                        if (selectedPaymentMethod == 'Card')
                          _buildCardDetailsSection(),
                        if (selectedPaymentMethod == 'UPI') _buildUPISection(),
                        if (selectedPaymentMethod == 'Bank Transfer')
                          _buildBankTransferSection(),
                        _buildItemsListCard(),
                        SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildHeader() {
    return Container(
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
                      'Payment - Step 3',
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
                  ],
                ),
              ),
              // Payment Status Indicator
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: paymentValidated ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      paymentValidated ? Icons.verified : Icons.access_time,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      paymentValidated ? 'Validated' : 'Pending',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // 4-Step Progress (same as cart screen)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildStep(0, 'Customer', Icons.person, false),
                _buildStepLine(),
                _buildStep(1, 'Cart', Icons.shopping_cart, false),
                _buildStepLine(),
                _buildStep(2, 'Payment', Icons.payment, true), // Active step
                _buildStepLine(),
                _buildStep(3, 'Receipt', Icons.receipt, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int index, String title, IconData icon, bool isActive) {
    bool isPast = index < 2;

    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive
                ? Color(0xFFD4AF37)
                : isPast
                    ? Colors.green
                    : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPast ? Icons.check : icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: isActive
                ? Color(0xFFD4AF37)
                : isPast
                    ? Colors.green
                    : Colors.grey[600],
            fontWeight:
                isActive || isPast ? FontWeight.w600 : FontWeight.normal,
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

  Widget _buildOrderSummaryCard() {
    return Container(
      padding: EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(Icons.receipt_long, color: Color(0xFFD4AF37), size: 24),
              SizedBox(width: 12),
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildSummaryRow('Items', '${widget.cartItems.length} products'),
          _buildSummaryRow(
              'Gold Rate', '₹${widget.goldRate.toStringAsFixed(0)}/g'),
          _buildSummaryRow('GST Rate', '${widget.gstRate}%'),
          Divider(height: 24),
          _buildCalculationRow('Subtotal', subtotal, false),
          _buildCalculationRow('GST (${widget.gstRate}%)', gstAmount, false),
          Divider(height: 16),
          ScaleTransition(
            scale: _pulseAnimation,
            child: _buildCalculationRow('Total Amount', total, true),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(String label, double amount, bool isTotal) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.grey[800] : Colors.grey[600],
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Container(
            padding: isTotal
                ? EdgeInsets.symmetric(horizontal: 12, vertical: 6)
                : null,
            decoration: isTotal
                ? BoxDecoration(
                    color: Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Text(
              '₹${amount.toStringAsFixed(0)}',
              style: TextStyle(
                color: isTotal ? Colors.white : Colors.grey[800],
                fontSize: isTotal ? 20 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      padding: EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(Icons.payment, color: Color(0xFFD4AF37), size: 24),
              SizedBox(width: 12),
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...paymentMethods
              .map((method) => _buildPaymentOption(method))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(PaymentMethod method) {
    bool isSelected = selectedPaymentMethod == method.name;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPaymentMethod = method.name;
            // Reset selections when changing payment method
            selectedUPIMethod = '';
            selectedBankMethod = '';
            paymentValidated = false;
          });
          HapticFeedback.selectionClick();
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? Color(0xFFD4AF37).withOpacity(0.1)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Color(0xFFD4AF37) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFFD4AF37) : Colors.grey[400],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  method.icon,
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
                      method.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      method.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardDetailsSection() {
    return Container(
      padding: EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(Icons.credit_card, color: Color(0xFFD4AF37), size: 24),
              SizedBox(width: 12),
              Text(
                'Card Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Cardholder Name
          _buildTextField(
            'Cardholder Name',
            Icons.person_outline,
            _cardHolderController,
            TextInputType.text,
          ),
          SizedBox(height: 16),

          // Card Number
          _buildTextField(
            'Card Number',
            Icons.credit_card,
            _cardNumberController,
            TextInputType.number,
            hintText: '1234 5678 9012 3456',
          ),
          SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Expiry',
                  Icons.calendar_today,
                  _expiryController,
                  TextInputType.number,
                  hintText: 'MM/YY',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'CVV',
                  Icons.lock_outline,
                  _cvvController,
                  TextInputType.number,
                  hintText: '123',
                  isPassword: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUPISection() {
    return Container(
      padding: EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(Icons.qr_code_scanner, color: Color(0xFFD4AF37), size: 24),
              SizedBox(width: 12),
              Text(
                'Choose UPI App',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // UPI Apps Grid
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: upiMethods.length,
            itemBuilder: (context, index) {
              UPIMethod method = upiMethods[index];
              bool isSelected = selectedUPIMethod == method.name;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedUPIMethod = method.name;
                  });
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? method.color.withOpacity(0.1)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? method.color : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        method.icon,
                        color: method.color,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          method.displayName,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: method.color, size: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBankTransferSection() {
    return Container(
      padding: EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(Icons.account_balance, color: Color(0xFFD4AF37), size: 24),
              SizedBox(width: 12),
              Text(
                'Bank Transfer Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Bank Transfer Methods
          ...bankMethods.map((method) {
            bool isSelected = selectedBankMethod == method.name;

            return Container(
              margin: EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedBankMethod = method.name;
                  });
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? method.color.withOpacity(0.1)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? method.color : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        method.icon,
                        color: method.color,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method.displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              method.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: method.color, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),

          if (selectedBankMethod.isNotEmpty) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bank Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildBankDetail('Account Name', 'Jewelry Shop Ltd.'),
                  _buildBankDetail('Account Number', '1234567890123456'),
                  _buildBankDetail('IFSC Code', 'HDFC0001234'),
                  _buildBankDetail('Amount', '₹${total.toStringAsFixed(0)}'),
                  _buildBankDetail('Reference',
                      'PAY${DateTime.now().millisecondsSinceEpoch}'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBankDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller,
    TextInputType type, {
    String? hintText,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Color(0xFFD4AF37)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFD4AF37)),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildItemsListCard() {
    return Container(
      padding: EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(Icons.diamond, color: Color(0xFFD4AF37), size: 24),
              SizedBox(width: 12),
              Text(
                'Order Items (${widget.cartItems.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...widget.cartItems.asMap().entries.map((entry) {
            int index = entry.key;
            CartItem item = entry.value;
            return _buildOrderItem(item, index);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOrderItem(CartItem item, int index) {
    double itemTotal = _calculateItemTotal(item);

    return Container(
      margin:
          EdgeInsets.only(bottom: index < widget.cartItems.length - 1 ? 12 : 0),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFFD4AF37),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getProductIcon(item.type),
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  '${item.weight}g • ${item.purity} • Qty: ${item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${itemTotal.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF37),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    bool canProceed = _canProceedWithPayment();

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
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[400]!),
              ),
              icon: Icon(Icons.arrow_back, color: Colors.grey[600]),
              label: Text('Back to Cart',
                  style: TextStyle(color: Colors.grey[600])),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: (isProcessingPayment || !canProceed)
                  ? null
                  : () => _validateAndProcessPayment(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD4AF37),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey[400],
              ),
              icon: isProcessingPayment
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.payment),
              label: Text(
                isProcessingPayment
                    ? 'Processing...'
                    : !canProceed
                        ? 'Complete Details'
                        : 'Process Payment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceedWithPayment() {
    switch (selectedPaymentMethod) {
      case 'Cash':
        return true;
      case 'Card':
        return _cardNumberController.text.length >= 16 &&
            _expiryController.text.length >= 5 &&
            _cvvController.text.length >= 3 &&
            _cardHolderController.text.isNotEmpty;
      case 'UPI':
        return selectedUPIMethod.isNotEmpty;
      case 'Bank Transfer':
        return selectedBankMethod.isNotEmpty;
      default:
        return false;
    }
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

  void _validateAndProcessPayment() async {
    setState(() {
      isProcessingPayment = true;
    });

    await Future.delayed(Duration(seconds: 3));

    setState(() {
      isProcessingPayment = false;
      paymentValidated = true;
    });

    _showPaymentSuccessDialog();
  }

  void _showPaymentSuccessDialog() {
    _successController.forward();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Payment of ₹${total.toStringAsFixed(0)} processed successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildDialogRow('Payment Method:', selectedPaymentMethod),
                    _buildDialogRow('Transaction ID:',
                        'TXN${DateTime.now().millisecondsSinceEpoch}'),
                    _buildDialogRow('Amount:', '₹${total.toStringAsFixed(0)}'),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: Text('Back to Cart'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _completeSale();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFD4AF37),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Complete Sale'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeSale() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFD4AF37)),
                SizedBox(height: 16),
                Text(
                  'Completing Sale...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      List<Map<String, dynamic>> saleItems = widget.cartItems
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

      String saleId = await _firestoreService.createSale(
        customerId: widget.customerId,
        customerName: widget.customerName,
        items: saleItems,
        subtotal: subtotal,
        gstAmount: gstAmount,
        total: total,
        goldRate: widget.goldRate,
        paymentMethod: selectedPaymentMethod,
      );

      Navigator.pop(context);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptScreen(
            saleId: saleId,
            customerId: widget.customerId,
            customerName: widget.customerName,
            cartItems: widget.cartItems,
            subtotal: subtotal,
            gstAmount: gstAmount,
            total: total,
            goldRate: widget.goldRate,
            paymentMethod: selectedPaymentMethod,
            saleDate: DateTime.now(),
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing sale: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Model Classes
class PaymentMethod {
  final String name;
  final IconData icon;
  final List<Color> gradient;
  final String description;

  PaymentMethod({
    required this.name,
    required this.icon,
    required this.gradient,
    required this.description,
  });
}

class UPIMethod {
  final String name;
  final String displayName;
  final IconData icon;
  final Color color;

  UPIMethod({
    required this.name,
    required this.displayName,
    required this.icon,
    required this.color,
  });
}

class BankMethod {
  final String name;
  final String displayName;
  final IconData icon;
  final String description;
  final Color color;

  BankMethod({
    required this.name,
    required this.displayName,
    required this.icon,
    required this.description,
    required this.color,
  });
}

class CartItem {
  final String productId;
  final String name;
  final String type;
  final double weight;
  final String purity;
  final double makingCharges;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.type,
    required this.weight,
    required this.purity,
    required this.makingCharges,
    this.quantity = 1,
  });
}
