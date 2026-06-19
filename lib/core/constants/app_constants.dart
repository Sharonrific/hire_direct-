// lib/core/constants/app_constants.dart

class AppConstants {
  // App Info
  static const String appName = 'Hire Direct';
  static const String appTagline = 'Hire Direct. Work Direct.';
  static const String appVersion = '1.0.0';

  // Colors (as hex strings for reference)
  static const String primaryColorHex = '#1e3a8a';
  static const String accentColorHex = '#22c55e';

  // Commitment Fee
  static const double commitmentFee = 20.0;
  static const String commitmentFeeDesc =
      'A \$20 commitment fee is required to book. '
      'If both parties show up, it is refunded or applied to the job. '
      'If one party is a no-show, the on-time person receives the fee.';

  // Stripe
  static const String stripePublishableKey = 'YOUR_STRIPE_PUBLISHABLE_KEY';
  static const String stripeMerchantId = 'YOUR_MERCHANT_ID';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String jobsCollection = 'jobs';
  static const String bookingsCollection = 'bookings';
  static const String reviewsCollection = 'reviews';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String addOnsCollection = 'addOns';
  static const String notificationsCollection = 'notifications';

  // Google Translate
  static const String googleTranslateApiKey = 'YOUR_GOOGLE_TRANSLATE_API_KEY';

  // Job Categories
  static const List<String> jobCategories = [
    'General Labor',
    'Lawn & Garden',
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Painting',
    'Cleaning',
    'Moving',
    'HVAC',
    'Roofing',
    'Flooring',
    'Masonry',
    'Pest Control',
    'Pool Service',
    'Handyman',
    'Appliance Repair',
    'Snow Removal',
    'Pressure Washing',
    'Tree Service',
    'Interior Design',
  ];

  // Supported Languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Spanish',
  };

  // Job Status
  static const String statusPosted = 'Posted';
  static const String statusBooked = 'Booked';
  static const String statusInProgress = 'In Progress';
  static const String statusAwaitingConfirmation = 'Awaiting Confirmation';
  static const String statusCompleted = 'Completed';
  static const String statusPaymentReleased = 'Payment Released';
  static const String statusCancelled = 'Cancelled';

  // Payment Types
  static const String paymentEscrow = 'Secure Payment (Escrow)';
  static const String paymentAfterCompletion = 'Pay After Completion';

  // Distance units
  static const String distanceUnit = 'mi';

  // Max image uploads
  static const int maxJobImages = 10;
  static const int maxPortfolioImages = 20;
}
