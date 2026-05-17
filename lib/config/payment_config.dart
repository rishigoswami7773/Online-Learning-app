class PaymentConfig {
  PaymentConfig._();

  static const String razorpayKeyId = 'rzp_test_SnK1Rbhkc90zsL';
  static const String razorpayKeySecret = 'nyP6AYLiImMWOOGtuZih4nhx';
  static const String currency = 'INR';
  static const String businessName = 'Learnify';

  static const double gstRate = 0.18;

  static double totalWithGst(double price) => price + (price * gstRate);

  static double gstAmount(double price) =>
      double.parse((price * gstRate).toStringAsFixed(2));
}
