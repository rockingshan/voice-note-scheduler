import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'category.g.dart';

@HiveType(typeId: 5)
class Category extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final int color;
  @HiveField(3)
  final bool isDefault;
  @HiveField(4)
  final List<String> keywords;
  @HiveField(5)
  final DateTime createdAt;

  Category({
    String? id,
    required this.name,
    required this.color,
    this.isDefault = false,
    this.keywords = const [],
    required this.createdAt,
  }) : id = id ?? const Uuid().v4();

  Category copyWith({
    String? id,
    String? name,
    int? color,
    bool? isDefault,
    List<String>? keywords,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      keywords: keywords ?? this.keywords,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'isDefault': isDefault,
      'keywords': keywords,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      isDefault: json['isDefault'] ?? false,
      keywords: List<String>.from(json['keywords'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
