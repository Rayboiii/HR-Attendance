enum SwapStatus { pending, approved, rejected, unknown }

SwapStatus swapStatusFromString(String? value) => switch (value) {
      'Pending' => SwapStatus.pending,
      'Approved' => SwapStatus.approved,
      'Rejected' => SwapStatus.rejected,
      _ => SwapStatus.unknown,
    };

class ShiftSwap {
  const ShiftSwap({
    required this.id,
    required this.requesterId,
    required this.targetUserId,
    required this.requesterShiftId,
    required this.status,
    required this.createdAt,
    this.requesterName,
    this.targetUserName,
    this.requesterShiftName,
    this.managerNote,
    this.resolvedAt,
  });

  final String id;
  final String requesterId;
  final String targetUserId;
  final String requesterShiftId;
  final SwapStatus status;
  final DateTime createdAt;
  final String? requesterName;
  final String? targetUserName;
  final String? requesterShiftName;
  final String? managerNote;
  final DateTime? resolvedAt;

  bool get isPending => status == SwapStatus.pending;

  factory ShiftSwap.fromJson(Map<String, dynamic> json) => ShiftSwap(
        id: json['id'] as String,
        requesterId: json['requesterId'] as String,
        targetUserId: json['targetUserId'] as String,
        requesterShiftId: json['requesterShiftId'] as String,
        status: swapStatusFromString(json['status'] as String?),
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        requesterName: json['requesterName'] as String?,
        targetUserName: json['targetUserName'] as String?,
        requesterShiftName: json['requesterShiftName'] as String?,
        managerNote: json['managerNote'] as String?,
        resolvedAt: json['resolvedAt'] == null
            ? null
            : DateTime.parse(json['resolvedAt'] as String).toLocal(),
      );
}
