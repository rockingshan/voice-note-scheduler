import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_note_scheduler/src/domain/entities/category.dart';

void main() {
  group('Category', () {
    test('Category constructor creates instance with default values', () {
      final now = DateTime.now();
      final category = Category(
        name: 'Work',
        color: Colors.blue.value,
        createdAt: now,
      );

      expect(category.name, equals('Work'));
      expect(category.color, equals(Colors.blue.value));
      expect(category.createdAt, equals(now));
      expect(category.isDefault, isFalse);
      expect(category.keywords, isEmpty);
      expect(category.id, isNotEmpty);
    });

    test('Category copyWith updates fields correctly', () {
      final now = DateTime.now();
      final category = Category(
        id: 'test-id',
        name: 'Work',
        color: Colors.blue.value,
        createdAt: now,
      );

      final updated = category.copyWith(
        name: 'Personal',
        isDefault: true,
        keywords: ['important', 'urgent'],
      );

      expect(updated.id, equals('test-id'));
      expect(updated.name, equals('Personal'));
      expect(updated.isDefault, isTrue);
      expect(updated.keywords, equals(['important', 'urgent']));
      expect(updated.color, equals(Colors.blue.value));
    });

    test('Category toJson/fromJson serialization', () {
      final now = DateTime.now();
      final category = Category(
        id: 'test-id',
        name: 'Work',
        color: Colors.blue.value,
        isDefault: true,
        keywords: ['meeting', 'deadline'],
        createdAt: now,
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

    test('Category fromJson with missing optional fields', () {
      final json = {
        'id': 'test-id',
        'name': 'Work',
        'color': Colors.blue.value,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final category = Category.fromJson(json);

      expect(category.isDefault, isFalse);
      expect(category.keywords, isEmpty);
    });

    test('Category with keywords list', () {
      final now = DateTime.now();
      final keywords = ['work', 'meeting', 'important'];
      final category = Category(
        name: 'Business',
        color: Colors.blue.value,
        keywords: keywords,
        createdAt: now,
      );

      expect(category.keywords, equals(keywords));
      expect(category.keywords.length, equals(3));
    });

    test('Default category has isDefault set to true', () {
      final now = DateTime.now();
      final defaultCategory = Category(
        name: 'General',
        color: Colors.blue.value,
        isDefault: true,
        createdAt: now,
      );

      expect(defaultCategory.isDefault, isTrue);
    });

    test('Category with different colors', () {
      final now = DateTime.now();
      final blueCategory = Category(
        name: 'Work',
        color: Colors.blue.value,
        createdAt: now,
      );

      final redCategory = Category(
        name: 'Personal',
        color: Colors.red.value,
        createdAt: now,
      );

      expect(blueCategory.color, equals(Colors.blue.value));
      expect(redCategory.color, equals(Colors.red.value));
      expect(blueCategory.color, isNot(equals(redCategory.color)));
    });
  });
}
