import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jwellery_billing/screens/payment_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ReceiptScreen extends StatefulWidget {
  final String saleId;
  final String customerId;
  final String customerName;
  final List<CartItem> cartItems;
  final double subtotal;
  final double gstAmount;
  final double total;
  final double goldRate;
  final String paymentMethod;
  final DateTime saleDate;

  const ReceiptScreen({
    super.key,
    required this.saleId,
    required this.customerId,
    required this.customerName,
    required this.cartItems,
    required this.subtotal,
    required this.gstAmount,
    required this.total,
    required this.goldRate,
    required this.paymentMethod,
    required this.saleDate,
  });

  @override
  _ReceiptScreenState createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _slideController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  bool isGeneratingPDF = false;
  bool isSharing = false;
  bool isPrinting = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

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

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _startAnimations() async {
    await Future.delayed(Duration(milliseconds: 300));
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildEnhancedHeader(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildEnhancedReceiptCard(),
                        SizedBox(height: 20),
                        _buildEnhancedActionButtons(),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildEnhancedBottomActions(),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey[50]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFD4AF37).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios, color: Color(0xFFD4AF37)),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFFD4AF37),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.receipt_long,
                                color: Colors.white, size: 20),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Receipt Generated',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.green[600]!],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 18, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          _buildStep(0, 'Customer', Icons.person_outline, false),
          _buildStepLine(true),
          _buildStep(1, 'Cart', Icons.shopping_cart_outlined, false),
          _buildStepLine(true),
          _buildStep(2, 'Payment', Icons.payment, false),
          _buildStepLine(true),
          _buildStep(3, 'Receipt', Icons.receipt, true),
        ],
      ),
    );
  }

  Widget _buildStep(int index, String title, IconData icon, bool isActive) {
    bool isPast = index < 3;

    return Column(
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFB8941F)])
                : isPast
                    ? LinearGradient(colors: [Colors.green, Colors.green[600]!])
                    : null,
            color: !isActive && !isPast ? Colors.grey[300] : null,
            shape: BoxShape.circle,
            boxShadow: isActive || isPast
                ? [
                    BoxShadow(
                      color: (isActive ? Color(0xFFD4AF37) : Colors.green)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            isPast && !isActive ? Icons.check : icon,
            color: Colors.white,
            size: 20,
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
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 3,
        margin: EdgeInsets.only(bottom: 28),
        decoration: BoxDecoration(
          gradient: isCompleted
              ? LinearGradient(colors: [Colors.green, Colors.green[600]!])
              : null,
          color: !isCompleted ? Colors.grey[300] : null,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildEnhancedReceiptCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildEnhancedReceiptHeader(),
          _buildEnhancedReceiptBody(),
        ],
      ),
    );
  }

  Widget _buildEnhancedReceiptHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFB8941F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.diamond, color: Colors.white, size: 28),
              ),
              SizedBox(width: 16),
              Column(
                children: [
                  Text(
                    'GOLDEN JEWELRY',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'PREMIUM COLLECTION',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              'OFFICIAL SALES RECEIPT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedReceiptBody() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReceiptInfoSection(),
          SizedBox(height: 24),
          _buildItemsSection(),
          SizedBox(height: 24),
          _buildBillSummarySection(),
          SizedBox(height: 24),
          _buildReceiptFooter(),
        ],
      ),
    );
  }

  Widget _buildReceiptInfoSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                'Transaction Details',
                [
                  ['Sale ID', widget.saleId],
                  ['Date & Time', _formatDateTime(widget.saleDate)],
                  ['Payment Method', widget.paymentMethod],
                ],
                Icons.receipt_long,
                Colors.blue,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard(
                'Customer Details',
                [
                  ['Name', widget.customerName],
                  ['Customer ID', widget.customerId],
                  ['Gold Rate', '₹${widget.goldRate.toStringAsFixed(0)}/g'],
                ],
                Icons.person,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(
      String title, List<List<String>> details, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...details
              .map((detail) => Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          detail[0],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Flexible(
                          child: Text(
                            detail[1],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shopping_bag, color: Color(0xFFD4AF37), size: 20),
            SizedBox(width: 8),
            Text(
              'Items Purchased',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFFD4AF37).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.cartItems.length} items',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4AF37),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildEnhancedItemsTable(),
      ],
    );
  }

  Widget _buildEnhancedItemsTable() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[800]!, Colors.grey[700]!],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Item Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Qty',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Amount',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items
          ...widget.cartItems.asMap().entries.map((entry) {
            int index = entry.key;
            CartItem item = entry.value;
            bool isEven = index % 2 == 0;

            return Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isEven ? Colors.white : Colors.grey[50],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFD4AF37), Color(0xFFB8941F)],
                            ),
                            borderRadius: BorderRadius.circular(8),
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
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${item.weight}g - ${item.purity} - Making: ₹${item.makingCharges}/g',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xFFD4AF37).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFB8941F)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₹${_calculateItemTotal(item).toStringAsFixed(0)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBillSummarySection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[50]!, Colors.orange[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: Color(0xFFD4AF37), size: 20),
              SizedBox(width: 8),
              Text(
                'Bill Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildCalculationRow('Subtotal', widget.subtotal, false),
          _buildCalculationRow('GST (3.0%)', widget.gstAmount, false),
          Divider(height: 24, thickness: 1, color: Colors.amber[300]),
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFB8941F)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹${widget.total.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.green[600]!],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'PAYMENT RECEIVED',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(String label, double amount, bool isTotal) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptFooter() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.indigo[50]!],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFFB8941F)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Thank you for your purchase!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'For any queries, please contact us with your Sale ID',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildContactInfo(Icons.phone, '+91 98765 43210'),
              _buildContactInfo(Icons.email, 'support@goldenjewelry.com'),
              _buildContactInfo(Icons.location_on, 'MG Road, Bangalore'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedActionButtons() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.share, color: Color(0xFFD4AF37), size: 24),
              SizedBox(width: 12),
              Text(
                'Export & Share Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildEnhancedActionButton(
                  icon: Icons.picture_as_pdf,
                  label: 'Export PDF',
                  color: Colors.red,
                  onPressed: isGeneratingPDF ? null : _showExportOptions,
                  isLoading: isGeneratingPDF,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedActionButton(
                  icon: Icons.print,
                  label: 'Print',
                  color: Colors.blue,
                  onPressed: isPrinting ? null : _printReceipt,
                  isLoading: isPrinting,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildEnhancedActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  color: Colors.green,
                  onPressed: isSharing ? null : _shareReceipt,
                  isLoading: isSharing,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedActionButton(
                  icon: Icons.copy,
                  label: 'Copy Details',
                  color: Colors.orange,
                  onPressed: _copyToClipboard,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onPressed == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPressed();
            },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? null
              : LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: onPressed == null ? Colors.grey[300] : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedBottomActions() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[400]!, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.home, color: Colors.grey[600]),
              label: Text(
                'Back to Home',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD4AF37),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              icon: Icon(Icons.add_shopping_cart),
              label: Text(
                'New Sale',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced PDF Content Builder with Dynamic Sizing
  pw.Widget _buildPDFContent() {
    // Calculate dynamic sizing based on number of items
    int itemCount = widget.cartItems.length;
    bool isCompactMode = itemCount > 6;
    bool isUltraCompactMode = itemCount > 10;

    double baseSpacing = isUltraCompactMode ? 8 : (isCompactMode ? 12 : 16);
    double sectionSpacing = isUltraCompactMode ? 10 : (isCompactMode ? 15 : 20);

    return pw.Padding(
      padding: pw.EdgeInsets.all(isUltraCompactMode ? 15 : 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Compact Professional Header
          _buildEnhancedPDFHeader(isCompactMode),
          pw.SizedBox(height: baseSpacing),

          // Receipt Info Banner
          _buildReceiptInfoBanner(isCompactMode),
          pw.SizedBox(height: sectionSpacing),

          // Customer & Transaction Details in Row
          _buildCompactDetailsSection(isCompactMode),
          pw.SizedBox(height: sectionSpacing),

          // Dynamic Items Table
          _buildDynamicItemsTable(isCompactMode, isUltraCompactMode),
          pw.SizedBox(height: sectionSpacing),

          // Compact Payment Summary
          _buildCompactPaymentSummary(isCompactMode),

          // Spacer to push footer to bottom
          pw.Spacer(),

          // Compact Footer
          _buildCompactFooter(isCompactMode),
        ],
      ),
    );
  }

  // Enhanced Header with Better Design
  pw.Widget _buildEnhancedPDFHeader(bool isCompact) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.amber800, PdfColors.amber600],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Padding(
        padding: pw.EdgeInsets.all(isCompact ? 12 : 16),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        padding: pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Text(
                          'D',
                          style: pw.TextStyle(
                            fontSize: isCompact ? 14 : 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        'GOLDEN JEWELRY',
                        style: pw.TextStyle(
                          fontSize: isCompact ? 18 : 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Premium Gold & Diamond Collection',
                    style: pw.TextStyle(
                      fontSize: isCompact ? 8 : 10,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(
                      horizontal: isCompact ? 8 : 12,
                      vertical: isCompact ? 4 : 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Text(
                    'EST. 1995',
                    style: pw.TextStyle(
                      fontSize: isCompact ? 7 : 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.amber800,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Shop No. 45, Jewelry Market',
                  style: pw.TextStyle(
                    fontSize: isCompact ? 7 : 8,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  'MG Road, Bangalore - 560001',
                  style: pw.TextStyle(
                    fontSize: isCompact ? 7 : 8,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Receipt Info Banner
  pw.Widget _buildReceiptInfoBanner(bool isCompact) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(
          vertical: isCompact ? 8 : 12, horizontal: isCompact ? 12 : 16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey900,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SALES RECEIPT',
                style: pw.TextStyle(
                  fontSize: isCompact ? 16 : 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'Receipt No: ${widget.saleId}',
                style: pw.TextStyle(
                  fontSize: isCompact ? 8 : 10,
                  color: PdfColors.grey300,
                ),
              ),
            ],
          ),
          pw.Row(
            children: [
              pw.Container(
                padding: pw.EdgeInsets.symmetric(
                    horizontal: isCompact ? 8 : 12,
                    vertical: isCompact ? 4 : 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green,
                  borderRadius: pw.BorderRadius.circular(15),
                ),
                child: pw.Text(
                  'PAID',
                  style: pw.TextStyle(
                    fontSize: isCompact ? 8 : 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                _formatDateTime(widget.saleDate),
                style: pw.TextStyle(
                  fontSize: isCompact ? 8 : 10,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Compact Details Section
  pw.Widget _buildCompactDetailsSection(bool isCompact) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _buildPDFInfoCard(
            'CUSTOMER DETAILS',
            [
              ['Name', widget.customerName],
              ['Customer ID', widget.customerId],
              ['Contact', '+91 XXXXX XXXXX'],
            ],
            PdfColors.blue50,
            PdfColors.blue800,
            isCompact,
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _buildPDFInfoCard(
            'TRANSACTION INFO',
            [
              ['Payment', widget.paymentMethod],
              ['Gold Rate', 'Rs.${widget.goldRate.toStringAsFixed(0)}/g'],
              ['GST No', '29ABCDE1234F1Z5'],
            ],
            PdfColors.green50,
            PdfColors.green800,
            isCompact,
          ),
        ),
      ],
    );
  }

  // Reusable Info Card
  pw.Widget _buildPDFInfoCard(String title, List<List<String>> details,
      PdfColor bgColor, PdfColor titleColor, bool isCompact) {
    return pw.Container(
      padding: pw.EdgeInsets.all(isCompact ? 10 : 12),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: titleColor, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: isCompact ? 9 : 10,
              fontWeight: pw.FontWeight.bold,
              color: titleColor,
            ),
          ),
          pw.SizedBox(height: isCompact ? 6 : 8),
          ...details
              .map((detail) => pw.Padding(
                    padding: pw.EdgeInsets.only(bottom: 3),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          detail[0],
                          style: pw.TextStyle(
                            fontSize: isCompact ? 7 : 8,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Flexible(
                          child: pw.Text(
                            detail[1],
                            style: pw.TextStyle(
                              fontSize: isCompact ? 7 : 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  // Dynamic Items Table that adjusts based on item count
  pw.Widget _buildDynamicItemsTable(bool isCompact, bool isUltraCompact) {
    double fontSize = isUltraCompact ? 6 : (isCompact ? 7 : 8);
    double headerFontSize = isUltraCompact ? 7 : (isCompact ? 8 : 9);
    double padding = isUltraCompact ? 4 : (isCompact ? 6 : 8);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: pw.BoxDecoration(
            color: PdfColors.amber,
            borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
          ),
          child: pw.Text(
            'ITEMS PURCHASED (${widget.cartItems.length} items)',
            style: pw.TextStyle(
              fontSize: headerFontSize + 1,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: pw.FixedColumnWidth(20), // S.No
            1: pw.FlexColumnWidth(3), // Description
            2: pw.FixedColumnWidth(25), // Qty
            3: pw.FixedColumnWidth(35), // Weight
            4: pw.FlexColumnWidth(2), // Rate
            5: pw.FlexColumnWidth(2), // Amount
          },
          children: [
            // Compact Header
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey800),
              children: [
                _buildCompactTableHeader('No', headerFontSize, padding),
                _buildCompactTableHeader(
                    'Item Description', headerFontSize, padding),
                _buildCompactTableHeader('Qty', headerFontSize, padding),
                _buildCompactTableHeader('Weight', headerFontSize, padding),
                _buildCompactTableHeader('Rate', headerFontSize, padding),
                _buildCompactTableHeader('Amount', headerFontSize, padding),
              ],
            ),

            // Dynamic Item Rows
            ...widget.cartItems.asMap().entries.map((entry) {
              int index = entry.key;
              CartItem item = entry.value;
              double itemTotal = _calculateItemTotal(item);
              double itemRate = itemTotal / item.quantity;

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: index % 2 == 0 ? PdfColors.white : PdfColors.grey50,
                ),
                children: [
                  _buildCompactTableCell('${index + 1}', fontSize, padding,
                      isCenter: true),
                  _buildCompactTableCell(
                    isUltraCompact
                        ? '${item.name}\n${item.purity}'
                        : '${item.name}\n${item.purity} - Making: Rs.${item.makingCharges}/g',
                    fontSize,
                    padding,
                  ),
                  _buildCompactTableCell('${item.quantity}', fontSize, padding,
                      isCenter: true),
                  _buildCompactTableCell(
                      '${item.weight.toStringAsFixed(1)}g', fontSize, padding,
                      isCenter: true),
                  _buildCompactTableCell(
                      'Rs.${itemRate.toStringAsFixed(0)}', fontSize, padding,
                      isCenter: true),
                  _buildCompactTableCell(
                    'Rs.${itemTotal.toStringAsFixed(0)}',
                    fontSize,
                    padding,
                    isCenter: true,
                    isBold: true,
                    bgColor: PdfColors.amber100,
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  // Compact Table Header
  pw.Widget _buildCompactTableHeader(
      String text, double fontSize, double padding) {
    return pw.Container(
      padding: pw.EdgeInsets.all(padding),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Compact Table Cell
  pw.Widget _buildCompactTableCell(
    String text,
    double fontSize,
    double padding, {
    bool isCenter = false,
    bool isBold = false,
    PdfColor? bgColor,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(padding),
      color: bgColor,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
        textAlign: isCenter ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  // Compact Payment Summary
  pw.Widget _buildCompactPaymentSummary(bool isCompact) {
    return pw.Row(
      children: [
        // Terms & Policies (Left Side)
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            padding: pw.EdgeInsets.all(isCompact ? 8 : 12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.blue200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TERMS & WARRANTY',
                  style: pw.TextStyle(
                    fontSize: isCompact ? 8 : 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '- Warranty: 1 Year Manufacturing\n'
                  '- Exchange: 30 Days with Receipt\n'
                  '- Hallmark Certified Products\n'
                  '- Contact: +91 98765 43210',
                  style: pw.TextStyle(
                    fontSize: isCompact ? 6 : 7,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        ),

        pw.SizedBox(width: 12),

        // Payment Summary (Right Side)
        pw.Expanded(
          child: pw.Container(
            padding: pw.EdgeInsets.all(isCompact ? 8 : 12),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfColors.amber50, PdfColors.amber100],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.amber300, width: 1),
            ),
            child: pw.Column(
              children: [
                _buildSummaryRow('Subtotal:',
                    'Rs.${widget.subtotal.toStringAsFixed(0)}', isCompact),
                _buildSummaryRow('GST (3%):',
                    'Rs.${widget.gstAmount.toStringAsFixed(0)}', isCompact),

                pw.Container(
                  margin: pw.EdgeInsets.symmetric(vertical: isCompact ? 4 : 6),
                  height: 1,
                  color: PdfColors.amber400,
                ),

                // Total Amount Highlight
                pw.Container(
                  width: double.infinity,
                  padding: pw.EdgeInsets.all(isCompact ? 6 : 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'TOTAL AMOUNT',
                        style: pw.TextStyle(
                          fontSize: isCompact ? 8 : 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'Rs.${widget.total.toStringAsFixed(0)}',
                        style: pw.TextStyle(
                          fontSize: isCompact ? 14 : 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: isCompact ? 4 : 6),

                pw.Container(
                  width: double.infinity,
                  padding: pw.EdgeInsets.symmetric(vertical: isCompact ? 3 : 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green,
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Text(
                    'PAYMENT RECEIVED',
                    style: pw.TextStyle(
                      fontSize: isCompact ? 7 : 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Summary Row Helper
  pw.Widget _buildSummaryRow(String label, String amount, bool isCompact) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isCompact ? 7 : 8,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            amount,
            style: pw.TextStyle(
              fontSize: isCompact ? 7 : 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  // Compact Footer
  pw.Widget _buildCompactFooter(bool isCompact) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(
          vertical: isCompact ? 8 : 12, horizontal: isCompact ? 12 : 16),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.amber800, PdfColors.amber600],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'THANK YOU FOR YOUR PURCHASE!',
            style: pw.TextStyle(
              fontSize: isCompact ? 10 : 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
          if (!isCompact) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Visit us again for exclusive offers and new collections!',
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.white,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
          pw.SizedBox(height: isCompact ? 4 : 6),
          pw.Text(
            'Golden Jewelry Store • support@goldenjewelry.com • GST: 29ABCDE1234F1Z5',
            style: pw.TextStyle(
              fontSize: isCompact ? 6 : 7,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Show export location options
  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.save_alt, color: Color(0xFFD4AF37)),
                SizedBox(width: 12),
                Text(
                  'Choose Export Location',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.folder_special, color: Colors.blue),
              title: Text('Downloads Folder'),
              subtitle: Text('Save to default downloads location'),
              onTap: () {
                Navigator.pop(context);
                _exportToPDF(useDownloads: true);
              },
            ),
            ListTile(
              leading: Icon(Icons.folder_open, color: Colors.green),
              title: Text('Choose Custom Location'),
              subtitle: Text('Pick any folder on your device'),
              onTap: () {
                Navigator.pop(context);
                _exportToPDF(useCustomLocation: true);
              },
            ),
            ListTile(
              leading: Icon(Icons.folder, color: Colors.orange),
              title: Text('Documents Folder'),
              subtitle: Text('Save to documents directory'),
              onTap: () {
                Navigator.pop(context);
                _exportToPDF(useDocuments: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToPDF({
    bool useDownloads = false,
    bool useDocuments = false,
    bool useCustomLocation = false,
  }) async {
    setState(() => isGeneratingPDF = true);

    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => _buildPDFContent(),
        ),
      );

      String? outputPath;

      if (useCustomLocation) {
        String? selectedDirectory =
            await FilePicker.platform.getDirectoryPath();
        if (selectedDirectory != null) {
          outputPath = '$selectedDirectory/receipt_${widget.saleId}.pdf';
        } else {
          setState(() => isGeneratingPDF = false);
          return;
        }
      } else if (useDownloads) {
        Directory? downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          outputPath = '${downloadsDir.path}/receipt_${widget.saleId}.pdf';
        } else {
          Directory? externalDir = await getExternalStorageDirectory();
          outputPath =
              '${externalDir?.path ?? ''}/Download/receipt_${widget.saleId}.pdf';
        }
      } else if (useDocuments) {
        Directory? documentsDir = await getApplicationDocumentsDirectory();
        outputPath = '${documentsDir.path}/receipt_${widget.saleId}.pdf';
      } else {
        Directory tempDir = await getTemporaryDirectory();
        outputPath = '${tempDir.path}/receipt_${widget.saleId}.pdf';
      }

      if (outputPath != null) {
        final file = File(outputPath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(await pdf.save());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('PDF saved successfully!')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () => _showFileLocation(outputPath!),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Error exporting PDF: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      setState(() => isGeneratingPDF = false);
    }
  }

  void _showFileLocation(String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.folder_open, color: Color(0xFFD4AF37)),
            SizedBox(width: 12),
            Text('File Saved'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your receipt has been saved to:'),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                path,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: path));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('File path copied to clipboard')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD4AF37)),
            child: Text('Copy Path', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt() async {
    setState(() => isPrinting = true);

    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => _buildPDFContent(),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error printing receipt: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      setState(() => isPrinting = false);
    }
  }

  Future<void> _shareReceipt() async {
    setState(() => isSharing = true);

    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => _buildPDFContent(),
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/receipt_${widget.saleId}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Receipt for Sale ID: ${widget.saleId} - Total: Rs.${widget.total.toStringAsFixed(0)}',
        subject: 'Purchase Receipt - Golden Jewelry Store',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing receipt: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      setState(() => isSharing = false);
    }
  }

  Future<void> _copyToClipboard() async {
    String receiptText = '''
GOLDEN JEWELRY STORE
Premium Gold & Diamond Collection

SALES RECEIPT
=======================================

TRANSACTION DETAILS:
- Sale ID: ${widget.saleId}
- Date: ${_formatDateTime(widget.saleDate)}
- Customer: ${widget.customerName} (ID: ${widget.customerId})
- Payment: ${widget.paymentMethod}
- Gold Rate: Rs.${widget.goldRate.toStringAsFixed(0)}/gram

ITEMS PURCHASED (${widget.cartItems.length} items):
${widget.cartItems.asMap().entries.map((entry) {
      int index = entry.key;
      CartItem item = entry.value;
      double itemTotal = _calculateItemTotal(item);
      return '${index + 1}. ${item.name}\n   - ${item.weight}g - ${item.purity} - Qty: ${item.quantity}\n   - Amount: Rs.${itemTotal.toStringAsFixed(0)}';
    }).join('\n\n')}

BILL SUMMARY:
- Subtotal: Rs.${widget.subtotal.toStringAsFixed(0)}
- GST (3%): Rs.${widget.gstAmount.toStringAsFixed(0)}
- TOTAL: Rs.${widget.total.toStringAsFixed(0)}
PAYMENT RECEIVED

=======================================
Thank you for your purchase!
Contact: +91 98765 43210
Email: support@goldenjewelry.com
Address: MG Road, Bangalore - 560001
''';

    await Clipboard.setData(ClipboardData(text: receiptText));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Receipt details copied to clipboard!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  double _calculateItemTotal(CartItem item) {
    double goldPrice = item.weight * widget.goldRate;
    double makingCharges = item.weight * item.makingCharges;
    return (goldPrice + makingCharges) * item.quantity;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
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
}
