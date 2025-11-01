// Base model class
class BaseModel {
  DateTime? createdAt;
  DateTime? updatedAt;

  BaseModel({
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  BaseModel.fromJson(Map<String, dynamic> json) {
    createdAt = DateTime.tryParse(json['created_at'] ?? '');
    updatedAt = DateTime.tryParse(json['updated_at'] ?? '');
  }
}