import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_note_scheduler/src/domain/entities/category.dart';

void main() {
  group('CategorySerialization', () {
    test('Category serialization and deserialization', () {
      final category = Category(
        id: 'test-id',
        name: 'Work',
        color: Colors.blue.value,
        isDefault: true,
        keywords: ['meeting', 'deadline'],
        createdAt: DateTime.now(),
      );

      final json = category.toJson();
      final restored = Category.fromJson(json);

      expect(restored.id, equals(category.id));
      expect(restored.name, equals(category.name));
      expect(restored.color, equals(category.color));
      expect(restored.isDefault, equals(category.isDefault));
      expect(restored.keywords, equals(category.keywords));
      expect(restored.createdAt, equals(category.createdAt));
    });

    test('Category with empty keywords', () {
      final category = Category(
        id: 'test-id',
        name: 'General',
        color: Colors.blue.value,
        createdAt: DateTime.now(),
      );

      final json = category.toJson();
      final restored = Category.fromJson(json);

      expect(restored.keywords, isEmpty);
    });

    test('Category with different colors can be distinguished', () {
      final categories = [
        Category(
          name: 'Work',
          color: Colors.blue.value,
          createdAt: DateTime.now(),
        ),
        Category(
          name: 'Personal',
          color: Colors.red.value,
          createdAt: DateTime.now(),
        ),
        Category(
          name: 'Shopping',
          color: Colors.green.value,
          createdAt: DateTime.now(),
        ),
      ];

      final json = categories.map((c) => c.toJson()).toList();
      final restored = json.map((j) => Category.fromJson(j)).toList();

      expect(restored.length, equals(3));
      expect(restored[0].color, equals(Colors.blue.value));
      expect(restored[1].color, equals(Colors.red.value));
      expect(restored[2].color, equals(Colors.green.value));
    });

    test('Category default state', () {
      final defaultCategory = Category(
        name: 'General',
        color: Colors.blue.value,
        isDefault: true,
        createdAt: DateTime.now(),
      );

      final nonDefaultCategory = Category(
        name: 'Work',
        color: Colors.red.value,
        isDefault: false,
        createdAt: DateTime.now(),
      );

      expect(defaultCategory.isDefault, isTrue);
      expect(nonDefaultCategory.isDefault, isFalse);
    });
  });
}
