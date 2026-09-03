import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/asmaa_allah_model.dart';
import '../models/zikr_model.dart';

class AzkarRepository {
  List<ZikrModel>? _cachedAzkar;
  List<AsmaaAllahModel>? _cachedAsmaa;

  /// Load all Azkar
  Future<List<ZikrModel>> getAllAzkar() async {
    if (_cachedAzkar != null) return _cachedAzkar!;
    final jsonStr = await rootBundle.loadString('assets/data/azkar.json');
    final List<dynamic> list = json.decode(jsonStr) as List<dynamic>;
    _cachedAzkar = list.map((e) => ZikrModel.fromJson(e as Map<String, dynamic>)).toList();
    return _cachedAzkar!;
  }

  /// Get distinct Azkar categories with their count and categoryId
  Future<List<Map<String, dynamic>>> getCategories() async {
    final all = await getAllAzkar();
    final Map<String, Map<String, dynamic>> categoryMap = {};

    for (final z in all) {
      if (!categoryMap.containsKey(z.category)) {
        categoryMap[z.category] = {
          'category': z.category,
          'category_id': z.categoryId,
          'count': 1,
          'icon': _getCategoryIcon(z.categoryId),
        };
      } else {
        categoryMap[z.category]!['count'] = (categoryMap[z.category]!['count'] as int) + 1;
      }
    }

    return categoryMap.values.toList();
  }

  /// Get Azkar for a specific category
  Future<List<ZikrModel>> getAzkarByCategory(String category) async {
    final all = await getAllAzkar();
    return all.where((z) => z.category == category).toList();
  }

  /// Load 99 Names of Allah
  Future<List<AsmaaAllahModel>> getAsmaaAllah() async {
    if (_cachedAsmaa != null) return _cachedAsmaa!;
    final jsonStr = await rootBundle.loadString('assets/data/asmaa_allah.json');
    final List<dynamic> list = json.decode(jsonStr) as List<dynamic>;
    _cachedAsmaa = list.map((e) => AsmaaAllahModel.fromJson(e as Map<String, dynamic>)).toList();
    return _cachedAsmaa!;
  }

  String _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'sabah':
        return 'wb_sunny';
      case 'masaa':
        return 'nights_stay';
      case 'after_prayer':
        return 'mosque';
      case 'sleep':
        return 'bedtime';
      case 'waking':
        return 'alarm';
      case 'quranic_duas':
        return 'menu_book';
      case 'prophetic_duas':
        return 'favorite';
      case 'ruqyah':
        return 'shield';
      default:
        return 'auto_stories';
    }
  }
}
