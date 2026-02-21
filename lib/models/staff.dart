
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'staff.freezed.dart';
part 'staff.g.dart';

@freezed
class Staff with _$Staff {
  const factory Staff({
    required String id,
    required String name,
    required String email,
    required String role, // e.g., 'admin', 'cashier', 'manager'
    @Default(true) bool isActive,
    String? imageUrl,
  }) = _Staff;

  factory Staff.fromJson(Map<String, dynamic> json) => _$StaffFromJson(json);
}

// TODO: Implement StaffService for data operations
