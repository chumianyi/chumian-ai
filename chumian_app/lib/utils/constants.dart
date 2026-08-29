/// 全局常量定义：模型清单、标签体系、SVIP 权益、帮助文案等。
/// 本文件全部为本地静态数据，不发起任何网络请求。
library;

import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// 可用的对话模型清单（用于本地展示与选择，实际调用逻辑在 ApiService）。
class AppModels {
  AppModels._();

  static const String defaultModel = 'glm-4-flash';

  static const List<ModelOption> all = [
    ModelOption(
      id: 'glm-4-flash',
      name: 'GLM-4-Flash',
      tag: '快速',
      description: '轻量快速，适合日常问答与文本处理',
      color: Color(0xFF4D8DFF),
    ),
    ModelOption(
      id: 'glm-4-flash-250414',
      name: 'GLM-4-Flash 250414',
      tag: '稳定',
      description: 'GLM-4-Flash 稳定版本，兼容性佳',
      color: Color(0xFF34C77B),
    ),
    ModelOption(
      id: 'glm-4.7-flash',
      name: 'GLM-4.7-Flash',
      tag: '最新',
      description: '新一代推理模型，理解能力更强',
      color: Color(0xFF9C6ADE),
    ),
    ModelOption(
      id: 'glm-z1-flash',
      name: 'GLM-Z1-Flash',
      tag: '推理',
      description: '具备思考过程的推理模型',
      color: Color(0xFFF0455C),
    ),
    ModelOption(
      id: 'glm-4v-flash',
      name: 'GLM-4V-Flash',
      tag: '视觉',
      description: '支持图片输入的多模态模型',
      color: Color(0xFFF5A623),
    ),
    ModelOption(
      id: 'glm-4.6v-flash',
      name: 'GLM-4.6V-Flash',
      tag: '视觉',
      description: '增强版视觉理解模型',
      color: Color(0xFFFF6B9D),
    ),
    ModelOption(
      id: 'glm-4.1v-thinking-flash',
      name: 'GLM-4.1V-Thinking',
      tag: '推理',
      description: '带思考链的视觉推理模型',
      color: Color(0xFFB39DDB),
    ),
    ModelOption(
      id: 'cogview-3-flash',
      name: 'CogView-3-Flash',
      tag: '绘图',
      description: '文生图模型，根据描述生成图片',
      color: Color(0xFF3D7BF0),
    ),
    ModelOption(
      id: 'cogvideox-flash',
      name: 'CogVideoX-Flash',
      tag: '视频',
      description: '文生视频模型，支持生成短视频',
      color: Color(0xFFE8445C),
    ),
  ];

  static ModelOption optionOf(String? id) {
    for (final m in all) {
      if (m.id == id) return m;
    }
    return all.first;
  }
}

class ModelOption {
  final String id;
  final String name;
  final String tag;
  final String description;
  final Color color;

  const ModelOption({
    required this.id,
    required this.name,
    required this.tag,
    required this.description,
    required this.color,
  });
}

/// 探索页的分类体系。
class ExploreCategories {
  ExploreCategories._();

  static const List<ExploreCategory> all = [
    ExploreCategory(id: 'all', label: '全部', icon: Icons.grid_view_rounded),
    ExploreCategory(id: 'agent', label: '智能体', icon: Icons.smart_toy_outlined),
    ExploreCategory(id: 'image', label: '图片', icon: Icons.image_outlined),
    ExploreCategory(id: 'video', label: '视频', icon: Icons.videocam_outlined),
  ];

  static ExploreCategory of(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return all.first;
  }

  static String labelOf(String? id) => of(id ?? 'all').label;
}

class ExploreCategory {
  final String id;
  final String label;
  final IconData icon;

  const ExploreCategory({
    required this.id,
    required this.label,
    required this.icon,
  });
}

/// 积分与数值展示的单位体系。
class Units {
  Units._();

  static const double yi = 100000000;
  static const double wan = 10000;
}

/// SVIP 套餐信息（本地展示）。
class SvipPlans {
  SvipPlans._();

  static const List<SvipPlan> all = [
    SvipPlan(
      id: 'month',
      name: '月卡',
      price: '30',
      originalPrice: '45',
      days: 30,
      color: Color(0xFF4D8DFF),
      features: ['每日签到积分加成', '普通模型无限次数', '优先排队'],
    ),
    SvipPlan(
      id: 'quarter',
      name: '季卡',
      price: '80',
      originalPrice: '135',
      days: 90,
      color: Color(0xFF9C6ADE),
      features: ['月卡全部权益', '智能体数量翻倍', '专属客服通道'],
    ),
    SvipPlan(
      id: 'year',
      name: '年卡',
      price: '300',
      originalPrice: '540',
      days: 365,
      color: Color(0xFFF5A623),
      features: ['季卡全部权益', '高质模型不限次', '新功能抢先体验'],
    ),
  ];

  static SvipPlan of(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return all.first;
  }
}

class SvipPlan {
  final String id;
  final String name;
  final String price;
  final String originalPrice;
  final int days;
  final Color color;
  final List<String> features;

  const SvipPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.originalPrice,
    required this.days,
    required this.color,
    required this.features,
  });
}

/// 侧边栏 / 导航相关常量。
class NavMeta {
  NavMeta._();

  static const int tabChat = 0;
  static const int tabCreative = 1;
  static const int tabExplore = 2;
  static const int tabActivity = 3;
  static const int tabPoints = 4;
  static const int tabProfile = 5;

  static const List<String> tabTitles = ['对话', '创意', '探索', '活动', '积分', '我的'];
}

/// 帮助 / 关于文案（本地静态）。
class AboutTexts {
  AboutTexts._();

  static const String appName = '初眠AI';
  static const String slogan = '让每一次对话都更有温度';
  static const String version = '2.0.0';
  static const String build = '6';
  static const String copyright = '初眠AI 团队';

  static const List<String> features = [
    '多模型对话',
    '智能体创作',
    '创意社区',
    '积分与签到',
  ];
}

/// 常见错误提示文案映射（仅文案，不涉及网络）。
class ErrorMessages {
  ErrorMessages._();

  static String of(Object error) {
    final msg = error.toString();
    if (msg.contains('401')) return '登录已过期，请重新登录';
    if (msg.contains('403')) return '没有权限执行该操作';
    if (msg.contains('404')) return '请求的资源不存在';
    if (msg.contains('timeout')) return '请求超时，请检查网络后重试';
    if (msg.contains('SocketException')) return '网络连接失败，请稍后重试';
    if (msg.contains('DioException')) return '网络请求异常，请稍后重试';
    return '发生未知错误，请稍后重试';
  }
}

/// 头像占位配色池（本地生成头像底色）。
class AvatarPalette {
  AvatarPalette._();

  static const List<Color> colors = [
    Color(0xFF4D8DFF),
    Color(0xFF34C77B),
    Color(0xFF9C6ADE),
    Color(0xFFF0455C),
    Color(0xFFF5A623),
    Color(0xFF00BFC7),
    Color(0xFFFF6B9D),
    Color(0xFF7C4DFF),
  ];

  static Color of(String seed) {
    if (seed.isEmpty) return colors.first;
    var hash = 0;
    for (final c in seed.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return colors[hash % colors.length];
  }
}

/// 通知消息类型配置。
class NotificationTypes {
  NotificationTypes._();

  static const Map<String, NotificationStyle> styles = {
    'follow': NotificationStyle(
      label: '关注',
      icon: Icons.person_add_alt_1_rounded,
      color: Color(0xFF4D8DFF),
    ),
    'birthday': NotificationStyle(
      label: '生日',
      icon: Icons.cake_rounded,
      color: Color(0xFFFF6B9D),
    ),
    'activity': NotificationStyle(
      label: '活动',
      icon: Icons.local_activity_rounded,
      color: Color(0xFFF5A623),
    ),
    'system': NotificationStyle(
      label: '系统',
      icon: Icons.campaign_rounded,
      color: Color(0xFF9C6ADE),
    ),
    'points': NotificationStyle(
      label: '积分',
      icon: Icons.stars_rounded,
      color: Color(0xFF34C77B),
    ),
  };

  static NotificationStyle of(String type) => styles[type] ?? styles['system']!;
}

class NotificationStyle {
  final String label;
  final IconData icon;
  final Color color;

  const NotificationStyle({
    required this.label,
    required this.icon,
    required this.color,
  });
}
