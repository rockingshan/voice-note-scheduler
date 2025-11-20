import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:voice_note_scheduler/src/application/repositories/category_repository.dart';
import 'package:voice_note_scheduler/src/domain/entities/category.dart';
import 'package:voice_note_scheduler/src/data/datasources/hive_category_datasource.dart';
import 'package:voice_note_scheduler/src/data/repositories/category_repository.dart';

class MockCategoryDatasource extends Mock implements CategoryDatasource {}

void main() {
  late CategoryRepository repository;
  late MockCategoryDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockCategoryDatasource();
    repository = CategoryRepositoryImpl(mockDatasource);
  });

  group('CategoryRepository', () {
    test('createCategory calls datasource', () async {
      final category = Category(
        name: 'Work',
        color: Colors.blue.value,
        createdAt: DateTime.now(),
      );

      await repository.createCategory(category);

      verify(mockDatasource.createCategory(category)).called(1);
    });

    test('getCategoryById calls datasource', () async {
      final category = Category(
        id: 'test-id',
        name: 'Work',
        color: Colors.blue.value,
        createdAt: DateTime.now(),
      );

      when(mockDatasource.getCategoryById('test-id'))
          .thenAnswer((_) async => category);

      final result = await repository.getCategoryById('test-id');

      expect(result?.id, equals('test-id'));
      verify(mockDatasource.getCategoryById('test-id')).called(1);
    });

    test('getAllCategories calls datasource', () async {
      final categories = [
        Category(
          name: 'Work',
          color: Colors.blue.value,
          createdAt: DateTime.now(),
        ),
        Category(
          name: 'Personal',
          color: Colors.green.value,
          createdAt: DateTime.now(),
        ),
      ];

      when(mockDatasource.getAllCategories())
          .thenAnswer((_) async => categories);

      final result = await repository.getAllCategories();

      expect(result.length, equals(2));
      verify(mockDatasource.getAllCategories()).called(1);
    });

    test('getDefaultCategory returns category with isDefault=true', () async {
      final defaultCategory = Category(
        name: 'General',
        color: Colors.blue.value,
        isDefault: true,
        createdAt: DateTime.now(),
      );

      when(mockDatasource.getDefaultCategory())
          .thenAnswer((_) async => defaultCategory);

      final result = await repository.getDefaultCategory();

      expect(result?.isDefault, isTrue);
      verify(mockDatasource.getDefaultCategory()).called(1);
    });

    test('setDefaultCategory updates the default category', () async {
      final currentDefault = Category(
        id: 'default-id',
        name: 'General',
        color: Colors.blue.value,
        isDefault: true,
        createdAt: DateTime.now(),
      );

      final newDefault = Category(
        id: 'work-id',
        name: 'Work',
        color: Colors.green.value,
        isDefault: false,
        createdAt: DateTime.now(),
      );

      when(mockDatasource.getCategoryById('work-id'))
          .thenAnswer((_) async => newDefault);
      when(mockDatasource.getDefaultCategory())
          .thenAnswer((_) async => currentDefault);

      await repository.setDefaultCategory('work-id');

      verify(mockDatasource.getDefaultCategory()).called(1);
      verify(mockDatasource.updateCategory(any<Category>())).called(2);
    });

    test('updateCategory enforces single default constraint', () async {
      final currentDefault = Category(
        id: 'default-id',
        name: 'General',
        color: Colors.blue.value,
        isDefault: true,
        createdAt: DateTime.now(),
      );

      final updatingCategory = Category(
        id: 'work-id',
        name: 'Work',
        color: Colors.green.value,
        isDefault: true,
        createdAt: DateTime.now(),
      );

      when(mockDatasource.getDefaultCategory())
          .thenAnswer((_) async => currentDefault);

      await repository.updateCategory(updatingCategory);

      verify(mockDatasource.getDefaultCategory()).called(1);
      verify(mockDatasource.updateCategory(any<Category>())).called(2);
    });

    test('ensureDefaultCategory creates one if it does not exist', () async {
      when(mockDatasource.getDefaultCategory())
          .thenAnswer((_) async => null);

      final result = await repository.ensureDefaultCategory();

      expect(result.name, equals('General'));
      expect(result.isDefault, isTrue);
      verify(mockDatasource.createCategory(any<Category>())).called(1);
    });

    test('ensureDefaultCategory returns existing default category', () async {
      final existingDefault = Category(
        id: 'existing-id',
        name: 'General',
        color: Colors.blue.value,
        isDefault: true,
        createdAt: DateTime.now(),
      );

      when(mockDatasource.getDefaultCategory())
          .thenAnswer((_) async => existingDefault);

      final result = await repository.ensureDefaultCategory();

      expect(result.id, equals('existing-id'));
      verify(mockDatasource.getDefaultCategory()).called(1);
      verifyNever(mockDatasource.createCategory(any<Category>()));
    });

    test('deleteCategory calls datasource', () async {
      await repository.deleteCategory('test-id');

      verify(mockDatasource.deleteCategory('test-id')).called(1);
    });
  });
}
