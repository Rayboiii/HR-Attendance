class QrToken {
  const QrToken({
    required this.id,
    required this.shiftId,
    required this.token,
    required this.expiresAt,
    required this.isUsed,
  });

  final String id;
  final String shiftId;
  final String token;
  final DateTime expiresAt;
  final bool isUsed;

  factory QrToken.fromJson(Map<String, dynamic> json) => QrToken(
        id: json['id'] as String,
        shiftId: json['shiftId'] as String,
        token: json['token'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String).toLocal(),
        isUsed: json['isUsed'] as bool? ?? false,
      );
}
