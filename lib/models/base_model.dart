// Base model class
class BaseModel {
  bool success;
  String message;
  DateTime? createdAt;
  DateTime? updatedAt;

  BaseModel({
    required this.success,
    required this.message,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  BaseModel.fromJson(Map<String, dynamic> json)
    : success = json['success'] ?? false,
      message = json['message'] ?? '',
      createdAt = DateTime.tryParse(json['created_at'] ?? ''),
      updatedAt = DateTime.tryParse(json['updated_at'] ?? '');
}
