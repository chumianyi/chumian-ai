import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chumian_ai/models/theme_preset.dart';

/// ============================================================================
/// ThemePresetService —— 主题预设管理服务
///
/// 提供内置主题预设、用户自定义主题的保存/加载、导入导出
/// 以及应用当前主题的能力。基于 SharedPreferences 持久化。
/// ============================================================================
class ThemePresetService {
  // ===== 存储键 =====
  static const String _prefixCustom = 'theme_custom_';
  static const String _keyCustomIdList = 'theme_custom_id_list';
  static const String _keyCurrentThemeId = 'theme_current_id';
  static const String _keyCurrentTheme = 'theme_current';

  /// 单例实例
  static final ThemePresetService _instance =
      ThemePresetService._internal();
  factory ThemePresetService() => _instance;
  ThemePresetService._internal();

  SharedPreferences? _prefs;

  /// 初始化
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _ensurePrefs async {
    if (_prefs == null) await init();
    return _prefs!;
  }

  // ==========================================================================
  // 内置主题预设
  // ==========================================================================

  /// 获取所有内置主题预设
  List<ThemePreset> getBuiltinPresets() {
    return [
      ThemePreset(
        id: 'builtin_pink',
        name: '初眠粉',
        primaryColor: 0xFFFF6B9D,
        primaryLightColor: 0xFFFF8FB5,
        primaryDarkColor: 0xFFE8558A,
        backgroundColor: 0xFFFFF5F8,
        surfaceColor: 0xFFFFFAFC,
        textPrimaryColor: 0xFF2D2D3A,
        textSecondaryColor: 0xFF6E6E80,
        isDark: false,
        category: ThemePresetCategory.official,
        author: '初眠AI',
      ),
      ThemePreset(
        id: 'builtin_dark_pink',
        name: '暗夜粉',
        primaryColor: 0xFFFF8FB5,
        primaryLightColor: 0xFFFFB3CC,
        primaryDarkColor: 0xFFFF6B9D,
        backgroundColor: 0xFF1A1220,
        surfaceColor: 0xFF241A2E,
        textPrimaryColor: 0xFFF0E8F0,
        textSecondaryColor: 0xFFB0A0B8,
        isDark: true,
        category: ThemePresetCategory.official,
        author: '初眠AI',
      ),
      ThemePreset(
        id: 'builtin_lavender',
        name: '薰衣草紫',
        primaryColor: 0xFFB388FF,
        primaryLightColor: 0xFFD1B3FF,
        primaryDarkColor: 0xFF9966FF,
        backgroundColor: 0xFFF8F5FF,
        surfaceColor: 0xFFFDFBFF,
        textPrimaryColor: 0xFF2D2D3A,
        textSecondaryColor: 0xFF6E6E80,
        isDark: false,
        category: ThemePresetCategory.official,
        author: '初眠AI',
      ),
      ThemePreset(
        id: 'builtin_mint',
        name: '薄荷绿',
        primaryColor: 0xFF66D9B8,
        primaryLightColor: 0xFF99E6D0,
        primaryDarkColor: 0xFF4DC9A8,
        backgroundColor: 0xFFF0FFF9,
        surfaceColor: 0xFFFAFFFD,
        textPrimaryColor: 0xFF2D2D3A,
        textSecondaryColor: 0xFF6E6E80,
        isDark: false,
        category: ThemePresetCategory.official,
        author: '初眠AI',
      ),
      ThemePreset(
        id: 'builtin_ocean',
        name: '海洋蓝',
        primaryColor: 0xFF5BA8FF,
        primaryLightColor: 0xFF8CC4FF,
        primaryDarkColor: 0xFF3D91F5,
        backgroundColor: 0xFFF0F7FF,
        surfaceColor: 0xFFFAFCFF,
        textPrimaryColor: 0xFF2D2D3A,
        textSecondaryColor: 0xFF6E6E80,
        isDark: false,
        category: ThemePresetCategory.official,
        author: '初眠AI',
      ),
      ThemePreset(
        id: 'builtin_sunset',
        name: '日落橙',
        primaryColor: 0xFFFF9966,
        primaryLightColor: 0xFFFFBB99,
        primaryDarkColor: 0xFFFF7744,
        backgroundColor: 0xFFFFF8F0,
        surfaceColor: 0xFFFFFCFA,
        textPrimaryColor: 0xFF2D2D3A,
        textSecondaryColor: 0xFF6E6E80,
        isDark: false,
        category: ThemePresetCategory.official,
        author: '初眠AI',
      ),
    ];
  }

  /// 根据 ID 获取内置主题
  ThemePreset? getBuiltinPreset(String id) {
    for (final preset in getBuiltinPresets()) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  // ==========================================================================
  // 自定义主题管理
  // ==========================================================================

  Future<List<String>> _getCustomIdList() async {
    final prefs = await _ensurePrefs;
    final raw = prefs.getString(_keyCustomIdList);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _setCustomIdList(List<String> ids) async {
    final prefs = await _ensurePrefs;
    await prefs.setString(_keyCustomIdList, jsonEncode(ids));
  }

  /// 保存自定义主题
  Future<ThemePreset> saveCustomPreset(ThemePreset preset) async {
    final prefs = await _ensurePrefs;
    final toSave = preset.copyWith(isCustom: true);
    await prefs.setString(
      '$_prefixCustom${toSave.id}',
      jsonEncode(toSave.toJson()),
    );
    final ids = await _getCustomIdList();
    if (!ids.contains(toSave.id)) {
      ids.insert(0, toSave.id);
      await _setCustomIdList(ids);
    }
    return toSave;
  }

  /// 创建并保存新的自定义主题
  Future<ThemePreset> createCustomPreset({
    required String name,
    required Color primaryColor,
    required Color backgroundColor,
    Color? primaryLightColor,
    Color? primaryDarkColor,
    Color? surfaceColor,
    Color? textPrimaryColor,
    Color? textSecondaryColor,
    bool isDark = false,
  }) async {
    final preset = ThemePreset.createCustom(
      name: name,
      primaryColor: primaryColor.value,
      backgroundColor: backgroundColor.value,
      primaryLightColor: primaryLightColor?.value,
      primaryDarkColor: primaryDarkColor?.value,
      surfaceColor: surfaceColor?.value,
      textPrimaryColor: textPrimaryColor?.value,
      textSecondaryColor: textSecondaryColor?.value,
      isDark: isDark,
    );
    return saveCustomPreset(preset);
  }

  /// 获取所有自定义主题
  Future<List<ThemePreset>> getCustomPresets() async {
    final ids = await _getCustomIdList();
    final prefs = await _ensurePrefs;
    final presets = <ThemePreset>[];
    for (final id in ids) {
      final raw = prefs.getString('$_prefixCustom$id');
      if (raw != null && raw.isNotEmpty) {
        try {
          presets.add(ThemePreset.fromJson(
              Map<String, dynamic>.from(jsonDecode(raw) as Map)));
        } catch (_) {}
      }
    }
    return presets;
  }

  /// 获取单个自定义主题
  Future<ThemePreset?> getCustomPreset(String id) async {
    final prefs = await _ensurePrefs;
    final raw = prefs.getString('$_prefixCustom$id');
    if (raw == null || raw.isEmpty) return null;
    try {
      return ThemePreset.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  /// 删除自定义主题
  Future<bool> deleteCustomPreset(String id) async {
    final prefs = await _ensurePrefs;
    final key = '$_prefixCustom$id';
    if (!prefs.containsKey(key)) return false;
    await prefs.remove(key);
    final ids = await _getCustomIdList();
    ids.remove(id);
    await _setCustomIdList(ids);
    return true;
  }

  /// 获取所有主题（内置 + 自定义）
  Future<List<ThemePreset>> getAllPresets() async {
    final builtin = getBuiltinPresets();
    final custom = await getCustomPresets();
    return [...builtin, ...custom];
  }

  /// 根据 ID 获取任意主题
  Future<ThemePreset?> getPresetById(String id) async {
    final builtin = getBuiltinPreset(id);
    if (builtin != null) return builtin;
    return getCustomPreset(id);
  }

  // ==========================================================================
  // 当前主题
  // ==========================================================================

  /// 应用主题（保存当前主题状态）
  Future<void> applyPreset(ThemePreset preset) async {
    final prefs = await _ensurePrefs;
    await prefs.setString(_keyCurrentThemeId, preset.id);
    await prefs.setString(_keyCurrentTheme, jsonEncode(preset.toJson()));
  }

  /// 获取当前应用的主题
  Future<ThemePreset> getCurrentPreset() async {
    final prefs = await _ensurePrefs;
    final raw = prefs.getString(_keyCurrentTheme);
    if (raw != null && raw.isNotEmpty) {
      try {
        return ThemePreset.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map));
      } catch (_) {}
    }
    // 默认返回初眠粉
    return getBuiltinPresets().first;
  }

  /// 获取当前主题 ID
  Future<String?> getCurrentPresetId() async {
    final prefs = await _ensurePrefs;
    return prefs.getString(_keyCurrentThemeId);
  }

  // ==========================================================================
  // 导入导出
  // ==========================================================================

  /// 导出所有自定义主题为 JSON 字符串
  Future<String> exportCustomPresets() async {
    final presets = await getCustomPresets();
    return jsonEncode(presets.map((e) => e.toJson()).toList());
  }

  /// 从 JSON 字符串导入主题
  Future<int> importPresets(String jsonString) async {
    try {
      final list = jsonDecode(jsonString) as List<dynamic>;
      int count = 0;
      for (final item in list) {
        try {
          final preset = ThemePreset.fromJson(
              Map<String, dynamic>.from(item as Map));
          // 重新生成 ID 避免冲突
          final newPreset = preset.copyWith(
            id: 'theme_${DateTime.now().microsecondsSinceEpoch}_$count',
            isCustom: true,
            category: ThemePresetCategory.custom,
          );
          await saveCustomPreset(newPreset);
          count++;
        } catch (_) {}
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// 清除所有自定义主题
  Future<int> clearAllCustom() async {
    final ids = await _getCustomIdList();
    final prefs = await _ensurePrefs;
    int count = 0;
    for (final id in ids) {
      await prefs.remove('$_prefixCustom$id');
      count++;
    }
    await _setCustomIdList([]);
    return count;
  }
}
