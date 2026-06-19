// lib/data/services/payment_service.dart
import 'package:flutter/material.dart' show Color, ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class PaymentService {
  final Dio _dio = Dio();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // NOTE: In production, PaymentIntent creation MUST be done server-side
  // via a Firebase Cloud Function. This service calls that function.
  // Replace 'YOUR_CLOUD_FUNCTION_URL' with your deployed function URL.
  static const String _cloudFunctionUrl = 'YOUR_CLOUD_FUNCTION_URL';

  Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    required String description,
    required String customerId,
    String? jobId,
    String? paymentType, // 'escrow', 'commitment_fee', 'addon'
  }) async {
    try {
      // 1. Create PaymentIntent via Cloud Function
      final response = await _dio.post(
        '$_cloudFunctionUrl/createPaymentIntent',
        data: {
          'amount': (amount * 100).round(), // Stripe uses cents
          'currency': currency,
          'description': description,
          'customerId': customerId,
          'metadata': {
            'jobId': jobId ?? '',
            'paymentType': paymentType ?? '',
          },
        },
      );

      final clientSecret = response.data['clientSecret'] as String;
      final paymentIntentId = response.data['id'] as String;

      // 2. Present payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: AppConstants.appName,
          style: ThemeMode.light,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF1e3a8a),
            ),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      return PaymentResult(
        success: true,
        paymentIntentId: paymentIntentId,
        amount: amount,
      );
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return PaymentResult(success: false, error: 'Payment cancelled.');
      }
      return PaymentResult(success: false, error: e.error.localizedMessage);
    } catch (e) {
      // Demo mode when Cloud Function not configured
      if (_cloudFunctionUrl == 'YOUR_CLOUD_FUNCTION_URL') {
        return PaymentResult(
          success: true,
          paymentIntentId: 'demo_${DateTime.now().millisecondsSinceEpoch}',
          amount: amount,
          isDemo: true,
        );
      }
      return PaymentResult(success: false, error: e.toString());
    }
  }

  Future<PaymentResult> chargeCommitmentFee({
    required String userId,
    required String jobId,
    required String userType, // 'client' or 'worker'
  }) async {
    return processPayment(
      amount: AppConstants.commitmentFee,
      currency: 'usd',
      description: 'Commitment fee for job booking',
      customerId: userId,
      jobId: jobId,
      paymentType: 'commitment_fee',
    );
  }

  Future<PaymentResult> holdEscrow({
    required String clientId,
    required String jobId,
    required double amount,
  }) async {
    return processPayment(
      amount: amount,
      currency: 'usd',
      description: 'Escrow payment for job',
      customerId: clientId,
      jobId: jobId,
      paymentType: 'escrow',
    );
  }

  Future<PaymentResult> payAddOn({
    required String clientId,
    required String jobId,
    required String addOnId,
    required double amount,
    required String description,
  }) async {
    return processPayment(
      amount: amount,
      currency: 'usd',
      description: 'Add-on: $description',
      customerId: clientId,
      jobId: jobId,
      paymentType: 'addon',
    );
  }

  Future<void> releaseEscrow(String jobId, String paymentIntentId) async {
    // In production: call Cloud Function to release/transfer to worker
    await _dio.post(
      '$_cloudFunctionUrl/releaseEscrow',
      data: {'jobId': jobId, 'paymentIntentId': paymentIntentId},
    );
  }
}

class PaymentResult {
  final bool success;
  final String? paymentIntentId;
  final double? amount;
  final String? error;
  final bool isDemo;

  PaymentResult({
    required this.success,
    this.paymentIntentId,
    this.amount,
    this.error,
    this.isDemo = false,
  });
}

