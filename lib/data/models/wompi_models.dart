class WompiInitData {
  final String reference;
  final int amountInCents;
  final String currency;
  final String publicKey;
  final String signature;

  WompiInitData({
    required this.reference,
    required this.amountInCents,
    required this.currency,
    required this.publicKey,
    required this.signature,
  });

  factory WompiInitData.fromJson(Map<String, dynamic> json) {
    return WompiInitData(
      reference: json['reference']?.toString() ?? '',
      amountInCents: (json['amountInCents'] is num)
          ? (json['amountInCents'] as num).toInt()
          : 0,
      currency: json['currency']?.toString() ?? 'COP',
      publicKey: json['publicKey']?.toString() ?? '',
      signature: json['signature']?.toString() ?? '',
    );
  }
}

class WompiVerificationResult {
  final String status;
  final String message;
  final String? orderId;

  WompiVerificationResult({
    required this.status,
    required this.message,
    this.orderId,
  });

  bool get isApproved => status.toUpperCase() == 'APPROVED' || status.toUpperCase() == 'APROBADO';

  factory WompiVerificationResult.fromJson(Map<String, dynamic> json) {
    return WompiVerificationResult(
      status: json['status']?.toString() ?? 'DECLINED',
      message: json['message']?.toString() ?? '',
      orderId: json['orderId']?.toString(),
    );
  }
}
