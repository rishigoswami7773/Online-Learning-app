import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../config/payment_config.dart';
import '../../../routes/app_routes.dart';
import '../../../services/payment_service.dart';
import '../../../utils/theme_helper.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    required this.courseId,
    required this.courseName,
    required this.price,
    required this.mentorName,
    this.thumbnailUrl,
    super.key,
  });

  final String courseId;
  final String courseName;
  final double price;
  final String mentorName;
  final String? thumbnailUrl;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;
  // Keep Razorpay instance alive (unused but prevents dispose errors)
  final Razorpay _razorpay = Razorpay();

  double get _gst => PaymentConfig.gstAmount(widget.price);
  double get _total => PaymentConfig.totalWithGst(widget.price);

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    final paid = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RazorpaySheet(
        total: _total,
        courseName: widget.courseName,
        merchantName: PaymentConfig.businessName,
      ),
    );

    if (paid != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      await PaymentService.verifyAndEnroll(
        orderId: 'order_$ts',
        paymentId: 'pay_$ts',
        signature: 'sig_$ts',
        courseId: widget.courseId,
        courseName: widget.courseName,
        amount: _total,
      );
      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Enrollment failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Payment Successful! 🎉',
              style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You are enrolled in',
              style: Theme.of(
                ctx,
              ).textTheme.bodyMedium?.copyWith(color: context.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              widget.courseName,
              style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0E7C86),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '₹${_total.toStringAsFixed(0)} paid',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go(AppRoutes.studentMyCourses);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E7C86),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Learning →',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16).copyWith(bottom: 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Info Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: widget.thumbnailUrl != null
                              ? Image.network(
                                  widget.thumbnailUrl!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _placeholder(),
                                )
                              : _placeholder(),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.courseName,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.mentorName,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: context.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹${widget.price.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0E7C86),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'One-time purchase • Lifetime access',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Order Summary Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _row(
                          'Course Price',
                          '₹${widget.price.toStringAsFixed(0)}',
                        ),
                        _row('GST (18%)', '+ ₹${_gst.toStringAsFixed(0)}'),
                        const Divider(height: 20),
                        _row(
                          'Total Payable',
                          '₹${_total.toStringAsFixed(0)}',
                          bold: true,
                          valueColor: const Color(0xFF0E7C86),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // What's Included
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What's Included",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 10),
                        _feature('Lifetime access to course content'),
                        _feature('Certificate upon completion'),
                        _feature('Access on mobile & tablet'),
                        _feature('Progress saved automatically'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: context.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Secured by Razorpay',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Pay button
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: _isLoading ? null : _initiatePayment,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0E7C86), Color(0xFF17A2B8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0E7C86).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Pay ₹${_total.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 80,
    height: 80,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF0E7C86), Color(0xFF17A2B8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: const Icon(Icons.menu_book, color: Colors.white, size: 32),
  );

  Widget _row(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.textSecondary,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: valueColor ?? context.textPrimary,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _feature(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, size: 18, color: Colors.green),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.textPrimary),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Razorpay-lookalike payment sheet
// ─────────────────────────────────────────────────────────────────────────────

class _RazorpaySheet extends StatefulWidget {
  const _RazorpaySheet({
    required this.total,
    required this.courseName,
    required this.merchantName,
  });
  final double total;
  final String courseName;
  final String merchantName;

  @override
  State<_RazorpaySheet> createState() => _RazorpaySheetState();
}

class _RazorpaySheetState extends State<_RazorpaySheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Card fields
  final _cardNumCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  bool _obscureCvv = true;

  // UPI
  final _upiCtrl = TextEditingController();

  // Net banking
  String? _selectedBank;

  // OTP step
  bool _showOtp = false;
  bool _processing = false;
  final _otpCtrl = TextEditingController();

  // Which method triggered OTP
  String _paymentMethod = 'card';

  static const _teal = Color(0xFF072654);
  static const _razorBlue = Color(0xFF2D80F2);

  static const _banks = [
    'State Bank of India',
    'HDFC Bank',
    'ICICI Bank',
    'Axis Bank',
    'Kotak Mahindra Bank',
    'Punjab National Bank',
    'Bank of Baroda',
    'Canara Bank',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    final user = FirebaseAuth.instance.currentUser;
    _cardNameCtrl.text = user?.displayName ?? '';
    _cardNumCtrl.addListener(_fmtCard);
    _expiryCtrl.addListener(_fmtExpiry);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _cardNumCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _cardNameCtrl.dispose();
    _upiCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _fmtCard() {
    final raw = _cardNumCtrl.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (int i = 0; i < raw.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(raw[i]);
    }
    final fmt = buf.toString();
    if (_cardNumCtrl.text != fmt) {
      _cardNumCtrl.value = TextEditingValue(
        text: fmt,
        selection: TextSelection.collapsed(offset: fmt.length),
      );
    }
  }

  void _fmtExpiry() {
    final raw = _expiryCtrl.text.replaceAll('/', '');
    if (raw.length >= 3) {
      final fmt =
          '${raw.substring(0, 2)}/${raw.substring(2, raw.length > 4 ? 4 : raw.length)}';
      if (_expiryCtrl.text != fmt) {
        _expiryCtrl.value = TextEditingValue(
          text: fmt,
          selection: TextSelection.collapsed(offset: fmt.length),
        );
      }
    }
  }

  // ── helpers ─────────────────────────────────────────────────────────────
  InputDecoration _dec(String label, {String? hint, Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _razorBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      );

  void _goOtp(String method) {
    _paymentMethod = method;
    setState(() => _showOtp = true);
  }

  void _confirmPay() {
    if (_otpCtrl.text.length < 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter the OTP')));
      return;
    }
    setState(() => _processing = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  // ── card tab ─────────────────────────────────────────────────────────────
  Widget _cardTab() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Column(
      children: [
        TextField(
          controller: _cardNumCtrl,
          decoration: _dec(
            'Card Number',
            hint: '•••• •••• •••• ••••',
            suffix: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.credit_card,
                size: 20,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 19,
          buildCounter:
              (_, {required currentLength, required isFocused, maxLength}) =>
                  null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expiryCtrl,
                decoration: _dec('Expiry', hint: 'MM / YY'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 5,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _cvvCtrl,
                decoration: _dec(
                  'CVV',
                  hint: '•••',
                  suffix: IconButton(
                    icon: Icon(
                      _obscureCvv ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _obscureCvv = !_obscureCvv),
                  ),
                ),
                obscureText: _obscureCvv,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _cardNameCtrl,
          decoration: _dec('Name on Card'),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        _payBtn('Pay ₹${widget.total.toStringAsFixed(0)}', () {
          if (_cardNumCtrl.text.replaceAll(' ', '').length < 8) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Enter a valid card number')),
            );
            return;
          }
          _goOtp('card');
        }),
      ],
    ),
  );

  // ── UPI / GPay tab ────────────────────────────────────────────────────────
  Widget _upiTab() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick app buttons
        Row(
          children: [
            _upiApp(
              'GPay',
              Icons.g_mobiledata,
              Colors.blue,
              () => _goOtp('gpay'),
            ),
            const SizedBox(width: 12),
            _upiApp(
              'PhonePe',
              Icons.phone_android,
              const Color(0xFF5F259F),
              () => _goOtp('phonepe'),
            ),
            const SizedBox(width: 12),
            _upiApp(
              'Paytm',
              Icons.account_balance_wallet,
              const Color(0xFF00BAF2),
              () => _goOtp('paytm'),
            ),
            const SizedBox(width: 12),
            _upiApp(
              'BHIM',
              Icons.currency_rupee,
              Colors.orange,
              () => _goOtp('bhim'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or enter UPI ID',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _upiCtrl,
          decoration: _dec(
            'UPI ID',
            hint: 'yourname@upi',
            suffix: IconButton(
              icon: const Icon(
                Icons.check_circle_outline,
                color: _razorBlue,
                size: 20,
              ),
              onPressed: () {},
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _payBtn('Verify & Pay', () {
          if (_upiCtrl.text.isEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Enter a UPI ID')));
            return;
          }
          _goOtp('upi');
        }),
      ],
    ),
  );

  Widget _upiApp(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ],
        ),
      ),
    ),
  );

  // ── Net Banking tab ───────────────────────────────────────────────────────
  Widget _netBankingTab() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select your bank',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        RadioGroup<String>(
          groupValue: _selectedBank,
          onChanged: (value) => setState(() => _selectedBank = value),
          child: Column(
            children: _banks
                .map(
                  (bank) => RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(bank, style: const TextStyle(fontSize: 13)),
                    value: bank,
                    activeColor: _razorBlue,
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        _payBtn('Pay ₹${widget.total.toStringAsFixed(0)}', () {
          if (_selectedBank == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a bank')),
            );
            return;
          }
          _goOtp('netbanking');
        }),
      ],
    ),
  );

  // ── OTP step ──────────────────────────────────────────────────────────────
  Widget _otpStep() {
    final methodLabel =
        {
          'card': 'your card',
          'gpay': 'Google Pay',
          'phonepe': 'PhonePe',
          'paytm': 'Paytm',
          'bhim': 'BHIM',
          'upi': 'your UPI',
          'netbanking': 'your bank',
        }[_paymentMethod] ??
        'your account';

    return SingleChildScrollView(
      key: const ValueKey('otp'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sms_outlined, color: _razorBlue, size: 34),
          ),
          const SizedBox(height: 16),
          const Text(
            'OTP Verification',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter the OTP sent to $methodLabel\nto complete payment of ₹${widget.total.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _otpCtrl,
            decoration: _dec('Enter OTP', hint: '• • • • • •'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 14,
            ),
            buildCounter:
                (_, {required currentLength, required isFocused, maxLength}) =>
                    null,
          ),
          const SizedBox(height: 8),
          const Text(
            'Any OTP works for demo',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          _payBtn(
            _processing ? 'Verifying…' : 'Confirm Payment',
            _processing ? null : _confirmPay,
            loading: _processing,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _processing
                ? null
                : () => setState(() {
                    _showOtp = false;
                    _otpCtrl.clear();
                  }),
            child: const Text(
              '← Change payment method',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── shared pay button ─────────────────────────────────────────────────────
  Widget _payBtn(String label, VoidCallback? onTap, {bool loading = false}) =>
      SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: _razorBlue,
            disabledBackgroundColor: _razorBlue.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            elevation: 0,
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
        ),
      );

  // ── main build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      // Fix height so sheet doesn't resize awkwardly when keyboard appears
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Razorpay header ─────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: _teal,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield, color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      widget.merchantName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${widget.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  widget.courseName,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // ── Tab bar (hidden when OTP step is shown) ─────────────────────
          if (!_showOtp)
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: _razorBlue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: _razorBlue,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Card'),
                  Tab(text: 'UPI / GPay'),
                  Tab(text: 'Net Banking'),
                ],
              ),
            ),
          // ── Content ──────────────────────────────────────────────────────
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _showOtp
                  ? _otpStep()
                  : Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: [_cardTab(), _upiTab(), _netBankingTab()],
                      ),
                    ),
            ),
          ),
          // ── Razorpay footer ──────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 11, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Secured by  ',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                const Text(
                  'razorpay',
                  style: TextStyle(
                    color: _razorBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
