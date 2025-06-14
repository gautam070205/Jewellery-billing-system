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

  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

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
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _startAnimations() async {
    await Future.delayed(Duration(milliseconds: 200));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
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
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildReceiptCard(),
                      SizedBox(height: 16),
                      _buildActionButtons(),
                      SizedBox(height: 24),
                    ],
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
                      'Receipt - Step 4',
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
              // Success Status Indicator
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Completed',
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
                _buildStep(2, 'Payment', Icons.payment, false),
                _buildStepLine(),
                _buildStep(3, 'Receipt', Icons.receipt, true), // Active step
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int index, String title, IconData icon, bool isActive) {
    bool isPast = index < 3;

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
            isPast && !isActive ? Icons.check : icon,
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
        color: Colors.green, // All completed
        margin: EdgeInsets.only(bottom: 32),
      ),
    );
  }

  Widget _buildReceiptCard() {
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
        children: [
          _buildReceiptHeader(),
          _buildReceiptBody(),
        ],
      ),
    );
  }

  Widget _buildReceiptHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFFD4AF37),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.diamond, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                '✨ GOLDEN JEWELRY ✨',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Premium Gold & Diamond Jewelry',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'OFFICIAL RECEIPT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptBody() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReceiptSection('Transaction Details', [
            _buildDetailCard([
              _buildReceiptRow('Sale ID', widget.saleId, Icons.tag),
              _buildReceiptRow('Date & Time', _formatDateTime(widget.saleDate),
                  Icons.access_time),
              _buildReceiptRow('Customer', widget.customerName, Icons.person),
              _buildReceiptRow('Customer ID', widget.customerId, Icons.badge),
              _buildReceiptRow(
                  'Payment Method', widget.paymentMethod, Icons.payment),
              _buildReceiptRow(
                  'Gold Rate',
                  '₹${widget.goldRate.toStringAsFixed(0)}/gram',
                  Icons.trending_up),
            ]),
          ]),
          SizedBox(height: 24),
          _buildReceiptSection('Items Purchased', [
            _buildItemsTable(),
          ]),
          SizedBox(height: 24),
          _buildReceiptSection('Bill Summary', [
            _buildCalculationCard(),
          ]),
          SizedBox(height: 24),
          _buildReceiptFooter(),
        ],
      ),
    );
  }

  Widget _buildReceiptSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.receipt_long, color: Color(0xFFD4AF37), size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildReceiptRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Color(0xFFD4AF37)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
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

  Widget _buildItemsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
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
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(0xFFD4AF37),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            _getProductIcon(item.type),
                            color: Colors.white,
                            size: 16,
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
                                '${item.weight}g • ${item.purity} • Making: ₹${item.makingCharges}/g',
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
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFFD4AF37).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
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
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xFFD4AF37),
                        borderRadius: BorderRadius.circular(6),
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

  Widget _buildCalculationCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildCalculationRow('Subtotal', widget.subtotal, false),
          _buildCalculationRow('GST (3.0%)', widget.gstAmount, false),
          Divider(height: 24),
          ScaleTransition(
            scale: _pulseAnimation,
            child: _buildCalculationRow('Total Amount', widget.total, true),
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green,
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
              color: isTotal ? Colors.grey[800] : Colors.grey[600],
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Container(
            padding: isTotal
                ? EdgeInsets.symmetric(horizontal: 16, vertical: 8)
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

  Widget _buildReceiptFooter() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFD4AF37),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite, color: Colors.white, size: 16),
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
          SizedBox(height: 12),
          Text(
            'For any queries, please contact us with your Sale ID',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone, size: 14, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                '+91 98765 43210',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(width: 16),
              Icon(Icons.email, size: 14, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                'support@goldenjewelry.com',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
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
        children: [
          Row(
            children: [
              Icon(Icons.share, color: Color(0xFFD4AF37), size: 20),
              SizedBox(width: 8),
              Text(
                'Export & Share Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.picture_as_pdf,
                  label: 'Export PDF',
                  color: Colors.red,
                  onPressed: isGeneratingPDF ? null : _showExportOptions,
                  isLoading: isGeneratingPDF,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
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
                child: _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  color: Colors.green,
                  onPressed: isSharing ? null : _shareReceipt,
                  isLoading: isSharing,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
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

  Widget _buildActionButton({
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
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: onPressed == null ? Colors.grey[300] : color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
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
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[400]!),
              ),
              icon: Icon(Icons.home, color: Colors.grey[600]),
              label: Text('Back to Home',
                  style: TextStyle(color: Colors.grey[600])),
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
              ),
              icon: Icon(Icons.add_shopping_cart),
              label: Text(
                'New Sale',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
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
        // Let user choose location
        String? selectedDirectory =
            await FilePicker.platform.getDirectoryPath();
        if (selectedDirectory != null) {
          outputPath = '$selectedDirectory/receipt_${widget.saleId}.pdf';
        } else {
          setState(() => isGeneratingPDF = false);
          return; // User cancelled
        }
      } else if (useDownloads) {
        // Use downloads directory
        Directory? downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          outputPath = '${downloadsDir.path}/receipt_${widget.saleId}.pdf';
        } else {
          // Fallback to external storage
          Directory? externalDir = await getExternalStorageDirectory();
          outputPath =
              '${externalDir?.path ?? ''}/Download/receipt_${widget.saleId}.pdf';
        }
      } else if (useDocuments) {
        // Use documents directory
        Directory? documentsDir = await getApplicationDocumentsDirectory();
        outputPath = '${documentsDir.path}/receipt_${widget.saleId}.pdf';
      } else {
        // Default to temporary directory
        Directory tempDir = await getTemporaryDirectory();
        outputPath = '${tempDir.path}/receipt_${widget.saleId}.pdf';
      }

      if (outputPath != null) {
        final file = File(outputPath);

        // Create directory if it doesn't exist
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

  pw.Widget _buildPDFContent() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Professional Header with Company Details
        _buildPDFHeader(),
        pw.SizedBox(height: 20),

        // Receipt Title and Sale Info
        _buildPDFReceiptTitle(),
        pw.SizedBox(height: 20),

        // Two Column Layout for Customer and Transaction Details
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _buildPDFCustomerDetails()),
            pw.SizedBox(width: 20),
            pw.Expanded(child: _buildPDFTransactionDetails()),
          ],
        ),
        pw.SizedBox(height: 25),

        // Items Table
        _buildPDFItemsTable(),
        pw.SizedBox(height: 20),

        // Payment Summary
        _buildPDFPaymentSummary(),
        pw.SizedBox(height: 20),

        // Terms and Footer
        pw.Spacer(),
        _buildPDFTermsAndFooter(),
      ],
    );
  }

  pw.Widget _buildPDFHeader() {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'GOLDEN JEWELRY STORE',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Premium Gold & Diamond Jewelry',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'ESTABLISHED 1995',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.amber,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'Shop No. 45, Jewelry Market, MG Road, Bangalore - 560001',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.black),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('Phone: +91 98765 43210',
                        style:
                            pw.TextStyle(fontSize: 9, color: PdfColors.black)),
                    pw.SizedBox(width: 20),
                    pw.Text('Email: support@goldenjewelry.com',
                        style:
                            pw.TextStyle(fontSize: 9, color: PdfColors.black)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text('GST No: 29ABCDE1234F1Z5 | PAN: ABCDE1234F',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFReceiptTitle() {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(vertical: 15),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.amber, width: 3),
          bottom: pw.BorderSide(color: PdfColors.amber, width: 3),
        ),
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
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Original Copy for Customer',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Container(
            padding: pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.green,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'PAID',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFCustomerDetails() {
    return pw.Container(
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'BILL TO',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.amber,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildPDFDetailRow('Customer Name', widget.customerName),
          _buildPDFDetailRow('Customer ID', widget.customerId),
          _buildPDFDetailRow('Mobile', '+91 XXXXX XXXXX'),
          _buildPDFDetailRow(
              'Address', 'Customer Address Line 1\nCity, State - PIN'),
        ],
      ),
    );
  }

  pw.Widget _buildPDFTransactionDetails() {
    return pw.Container(
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TRANSACTION DETAILS',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.amber,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildPDFDetailRow('Receipt No', widget.saleId),
          _buildPDFDetailRow('Date & Time', _formatDateTime(widget.saleDate)),
          _buildPDFDetailRow('Payment Method', widget.paymentMethod),
          _buildPDFDetailRow('Gold Rate Today',
              'Rs.${widget.goldRate.toStringAsFixed(0)}/gram'),
          _buildPDFDetailRow('Served By', 'Sales Executive'),
        ],
      ),
    );
  }

  pw.Widget _buildPDFDetailRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 80,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFItemsTable() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ITEMS PURCHASED',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(3),
            2: pw.FlexColumnWidth(1),
            3: pw.FlexColumnWidth(1.2),
            4: pw.FlexColumnWidth(1.2),
            5: pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header Row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.amber),
              children: [
                _buildPDFTableHeader('S.No'),
                _buildPDFTableHeader('Item Description'),
                _buildPDFTableHeader('Qty'),
                _buildPDFTableHeader('Weight (g)'),
                _buildPDFTableHeader('Rate'),
                _buildPDFTableHeader('Amount'),
              ],
            ),
            // Item Rows
            ...widget.cartItems.asMap().entries.map((entry) {
              int index = entry.key;
              CartItem item = entry.value;
              double itemTotal = _calculateItemTotal(item);
              double itemRate = itemTotal / item.quantity;

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: index % 2 == 0 ? PdfColors.grey100 : PdfColors.white,
                ),
                children: [
                  _buildPDFTableCell('${index + 1}', isCenter: true),
                  _buildPDFTableCell(
                    '${item.name}\n${item.purity} Purity\nMaking: Rs.${item.makingCharges}/g',
                    isDescription: true,
                  ),
                  _buildPDFTableCell('${item.quantity}', isCenter: true),
                  _buildPDFTableCell('${item.weight.toStringAsFixed(1)}',
                      isCenter: true),
                  _buildPDFTableCell('Rs.${itemRate.toStringAsFixed(0)}',
                      isCenter: true),
                  _buildPDFTableCell('Rs.${itemTotal.toStringAsFixed(0)}',
                      isCenter: true, isBold: true),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPDFTableHeader(String text) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildPDFTableCell(String text,
      {bool isCenter = false,
      bool isDescription = false,
      bool isBold = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isDescription ? 8 : 9,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
        textAlign: isCenter ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildPDFPaymentSummary() {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Container(
            padding: pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PAYMENT INFORMATION',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.amber,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Payment Method: ${widget.paymentMethod}',
                    style: pw.TextStyle(fontSize: 9)),
                pw.Text('Transaction Status: COMPLETED',
                    style: pw.TextStyle(fontSize: 9)),
                pw.Text('Warranty: 1 Year on Manufacturing Defects',
                    style: pw.TextStyle(fontSize: 9)),
                pw.Text('Exchange Policy: 30 Days with Receipt',
                    style: pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            padding: pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.amber, width: 2),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                _buildPDFSummaryRow('Subtotal', widget.subtotal),
                _buildPDFSummaryRow('GST (3.0%)', widget.gstAmount),
                pw.Container(
                  margin: pw.EdgeInsets.symmetric(vertical: 8),
                  height: 1,
                  color: PdfColors.amber,
                ),
                pw.Container(
                  padding: pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTAL AMOUNT',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'Rs.${widget.total.toStringAsFixed(0)}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  padding: pw.EdgeInsets.symmetric(vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'PAYMENT RECEIVED',
                    style: pw.TextStyle(
                      fontSize: 10,
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

  pw.Widget _buildPDFSummaryRow(String label, double amount) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Text(
            'Rs.${amount.toStringAsFixed(0)}',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFTermsAndFooter() {
    return pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TERMS & CONDITIONS',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                '1. All jewelry items are sold with proper hallmark certification.\n'
                '2. Exchange is allowed within 30 days with original receipt and tags.\n'
                '3. Warranty covers manufacturing defects only, not wear and tear.\n'
                '4. Gold rate may vary daily as per market conditions.\n'
                '5. For any queries, please contact us with your receipt number.',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.symmetric(vertical: 15),
          decoration: pw.BoxDecoration(
            border:
                pw.Border(top: pw.BorderSide(color: PdfColors.amber, width: 2)),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'Thank you for choosing Golden Jewelry Store!',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.amber,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'We appreciate your trust in our premium jewelry collection.',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Visit us again for exclusive offers and new collections!',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPDFRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
RECEIPT

Sale ID: ${widget.saleId}
Date: ${_formatDateTime(widget.saleDate)}
Customer: ${widget.customerName}
Payment: ${widget.paymentMethod}

ITEMS:
${widget.cartItems.map((item) => '- ${item.name} (${item.quantity}x) - Rs.${_calculateItemTotal(item).toStringAsFixed(0)}').join('\n')}

TOTAL: Rs.${widget.total.toStringAsFixed(0)}

Thank you for your purchase!
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
