import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chumian_ai/models/entertainment_item.dart';

/// ============================================================================
/// EntertainmentService —— 娱乐内容服务
///
/// 提供笑话、运势、星座、脑筋急转弯等娱乐内容的本地数据管理，
/// 支持内容缓存、随机获取、收藏管理与按类型筛选。
/// ============================================================================
class EntertainmentService {
  // ===== 存储键 =====
  static const String _prefixContent = 'ent_content_';
  static const String _keyFavorites = 'ent_favorites';
  static const String _keyCache = 'ent_cache';
  static const String _keyDailyFortune = 'ent_daily_fortune_';

  /// 单例实例
  static final EntertainmentService _instance =
      EntertainmentService._internal();
  factory EntertainmentService() => _instance;
  EntertainmentService._internal();

  SharedPreferences? _prefs;
  final Random _random = Random();

  /// 初始化
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _ensurePrefs async {
    if (_prefs == null) await init();
    return _prefs!;
  }

  // ==========================================================================
  // 本地内容库（非伪造AI回复，为预置娱乐素材）
  // 内置笑话库
  // ==========================================================================

  static const List<String> _builtinJokes = [
    '为什么程序员总是分不清万圣节和圣诞节？因为 Oct 31 == Dec 25。',
    '老婆问我：你说我这身材是不是该减肥了？我说：你这不是胖，是瘦得不明显。',
    '医生说我有严重的强迫症，我说：医生，你说的"严重"是有多严重？能精确到小数点后两位吗？',
    '我问朋友：你知道为什么大海是蓝色的吗？朋友说：因为小鱼在里面吐泡泡，blue~blue~blue~',
    '今天去买西瓜，老板说不甜不要钱。我买了一个，回家一尝，果然不甜。第二天我去找老板，老板说：你昨天买的那个是"不要钱"系列的。',
    '我跟我爸说我想当演员，我爸说：你先把你房间那堆衣服演成叠好的样子再说。',
    '数学老师说：数学是一门严谨的学科。然后他在黑板上写了一个"显然可得"，我盯着看了半小时，显然不得。',
    '我妈让我去买酱油，说要"生抽"。我到了超市，对售货员说：给我来一瓶会跳舞的酱油。售货员：？？？我说：不是生抽吗？',
    '朋友问我：你有《时间简史》吗？我说：我有时间也不捡那玩意儿。',
    '今天面试，面试官问我：你最大的缺点是什么？我说：太诚实。面试官说：我不觉得这是缺点。我说：我不在乎你怎么想。',
  ];

  static const List<String> _builtinRiddles = [
    '问：什么东西越洗越脏？答：水。',
    '问：什么门永远关不上？答：球门。',
    '问：什么书在书店里买不到？答：遗书。',
    '问：什么东西有头无脚？答：砖。',
    '问：什么东西越热越爱出来？答：汗。',
    '问：什么车坐不了人？答：风车。',
    '问：什么布剪不断？答：瀑布。',
    '问：什么球不能踢？答：地球。',
  ];

  static const List<String> _builtinPoisonSoup = [
    '努力不一定成功，但不努力一定很舒服。',
    '世上无难事，只要肯放弃。',
    '你全力以赴的样子，真的很像在做无用功。',
    '不要灰心，人生就是这样，起起落落落落落落落落。',
    '虽然你单身，但你胖若两人。',
    '别人的颜值是天生的，你的丑是后天努力的结果。',
    '你以为有钱人很快乐吗？他们的快乐你根本想象不到。',
    '条条大路通罗马，但有人就出生在罗马。',
  ];

  static const List<String> _builtinLoveQuotes = [
    '你知道我最喜欢什么神吗？你的眼神。',
    '我觉得你特别像一款游戏。什么游戏？我的世界。',
    '你可以笑一下吗？我的咖啡忘记加糖了。',
    '我最近一直在找一家店。什么店？你的来电。',
    '你猜我想喝什么？不知道。我想呵护你。',
    '你知道我的缺点是什么吗？是缺点你。',
    '我是真的很喜欢你，就像天气预报说明天有雨，我都能听成明天有你。',
  ];

  // ==========================================================================
  // 内容获取
  // ==========================================================================

  /// 获取随机笑话
  Future<EntertainmentItem> getRandomJoke() async {
    final index = _random.nextInt(_builtinJokes.length);
    return EntertainmentItem.create(
      type: EntertainmentType.joke,
      content: _builtinJokes[index],
      category: '爆笑',
    );
  }

  /// 获取随机脑筋急转弯
  Future<EntertainmentItem> getRandomRiddle() async {
    final index = _random.nextInt(_builtinRiddles.length);
    return EntertainmentItem.create(
      type: EntertainmentType.riddle,
      content: _builtinRiddles[index],
      category: '益智',
    );
  }

  /// 获取随机毒鸡汤
  Future<EntertainmentItem> getRandomPoisonSoup() async {
    final index = _random.nextInt(_builtinPoisonSoup.length);
    return EntertainmentItem.create(
      type: EntertainmentType.poisonSoup,
      content: _builtinPoisonSoup[index],
      category: '扎心',
    );
  }

  /// 获取随机土味情话
  Future<EntertainmentItem> getRandomLoveQuote() async {
    final index = _random.nextInt(_builtinLoveQuotes.length);
    return EntertainmentItem.create(
      type: EntertainmentType.loveQuote,
      content: _builtinLoveQuotes[index],
      category: '撩妹',
    );
  }

  /// 获取每日运势（基于日期和星座的伪随机，同一天同一星座结果一致）
  Future<EntertainmentItem> getDailyFortune({String zodiac = ''}) async {
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month}-${now.day}';
    final prefs = await _ensurePrefs;
    final cacheKey = '$_keyDailyFortune${zodiac}_$dateKey';

    // 检查缓存
    final cached = prefs.getString(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      try {
        return EntertainmentItem.fromJson(
            Map<String, dynamic>.from(jsonDecode(cached) as Map));
      } catch (_) {}
    }

    // 生成运势
    final seed =
        (dateKey.hashCode + zodiac.hashCode) % 100;
    final overallLevel = seed % 5; // 0-4
    const levels = ['大凶', '小凶', '平', '小吉', '大吉'];
    const colors = ['#FF4D4F', '#FAAD14', '#9E9EB0', '#52C41A', '#FF6B9D'];

    final loveScore = (seed * 7) % 100 + 1;
    final careerScore = (seed * 13) % 100 + 1;
    final wealthScore = (seed * 17) % 100 + 1;
    final healthScore = (seed * 11) % 100 + 1;

    const luckyNumbers = [3, 7, 8, 14, 21, 28, 33, 42];
    final luckyNumber = luckyNumbers[seed % luckyNumbers.length];

    const luckyColorsList = ['粉色', '白色', '金色', '蓝色', '紫色', '绿色'];
    final luckyColor = luckyColorsList[seed % luckyColorsList.length];

    const suggestions = [
      '宜：早睡早起，多喝水。忌：熬夜刷手机。',
      '宜：主动沟通，表达心意。忌：冷战沉默。',
      '宜：整理房间，断舍离。忌：冲动消费。',
      '宜：学习新技能，充实自己。忌：拖延懒散。',
      '宜：约朋友聚会，放松心情。忌：独自emo。',
    ];
    final suggestion = suggestions[seed % suggestions.length];

    final content = '''【今日运势】
综合运势：${levels[overallLevel]}
爱情指数：$loveScore%
事业指数：$careerScore%
财运指数：$wealthScore%
健康指数：$healthScore%
幸运数字：$luckyNumber
幸运颜色：$luckyColor
$suggestion''';

    final item = EntertainmentItem.create(
      type: EntertainmentType.fortune,
      title: '${zodiac.isEmpty ? '今日' : zodiac}运势',
      content: content,
      category: levels[overallLevel],
      metadata: {
        'overall': levels[overallLevel],
        'overall_color': colors[overallLevel],
        'love': loveScore,
        'career': careerScore,
        'wealth': wealthScore,
        'health': healthScore,
        'lucky_number': luckyNumber,
        'lucky_color': luckyColor,
        'zodiac': zodiac,
        'date': dateKey,
      },
    );

    // 缓存
    await prefs.setString(cacheKey, jsonEncode(item.toJson()));
    return item;
  }

  // ==========================================================================
  // 内容缓存管理
  // ==========================================================================

  /// 缓存一条内容
  Future<void> cacheContent(EntertainmentItem item) async {
    final prefs = await _ensurePrefs;
    await prefs.setString(
      '$_prefixContent${item.id}',
      jsonEncode(item.toJson()),
    );
  }

  /// 获取缓存的内容列表
  Future<List<EntertainmentItem>> getCachedContent(
      {EntertainmentType? type, int limit = 50}) async {
    final prefs = await _ensurePrefs;
    final items = <EntertainmentItem>[];
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_prefixContent)) {
        final raw = prefs.getString(key);
        if (raw != null && raw.isNotEmpty) {
          try {
            final item = EntertainmentItem.fromJson(
                Map<String, dynamic>.from(jsonDecode(raw) as Map));
            if (type == null || item.type == type) {
              items.add(item);
            }
          } catch (_) {}
        }
      }
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (items.length > limit) return items.sublist(0, limit);
    return items;
  }

  /// 清除过期缓存（保留最近 N 条）
  Future<int> clearOldCache({int keepLatest = 100}) async {
    final all = await getCachedContent(limit: 10000);
    if (all.length <= keepLatest) return 0;
    final prefs = await _ensurePrefs;
    final toRemove = all.sublist(keepLatest);
    int count = 0;
    for (final item in toRemove) {
      await prefs.remove('$_prefixContent${item.id}');
      count++;
    }
    return count;
  }

  // ==========================================================================
  // 收藏管理
  // ==========================================================================

  /// 获取收藏列表
  Future<List<EntertainmentItem>> getFavorites(
      {EntertainmentType? type}) async {
    final prefs = await _ensurePrefs;
    final raw = prefs.getString(_keyFavorites);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final items = list
          .map((e) => EntertainmentItem.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
      if (type != null) {
        return items.where((e) => e.type == type).toList();
      }
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (_) {
      return [];
    }
  }

  /// 添加收藏
  Future<bool> addFavorite(EntertainmentItem item) async {
    final favorites = await getFavorites();
    // 去重
    if (favorites.any((e) => e.id == item.id)) return false;
    final updated = item.copyWith(isFavorite: true);
    favorites.insert(0, updated);
    final prefs = await _ensurePrefs;
    await prefs.setString(
        _keyFavorites, jsonEncode(favorites.map((e) => e.toJson()).toList()));
    return true;
  }

  /// 移除收藏
  Future<bool> removeFavorite(String id) async {
    final favorites = await getFavorites();
    final originalLength = favorites.length;
    favorites.removeWhere((e) => e.id == id);
    if (favorites.length == originalLength) return false;
    final prefs = await _ensurePrefs;
    await prefs.setString(
        _keyFavorites, jsonEncode(favorites.map((e) => e.toJson()).toList()));
    return true;
  }

  /// 判断是否已收藏
  Future<bool> isFavorite(String id) async {
    final favorites = await getFavorites();
    return favorites.any((e) => e.id == id);
  }

  /// 切换收藏状态
  Future<bool> toggleFavorite(EntertainmentItem item) async {
    if (await isFavorite(item.id)) {
      await removeFavorite(item.id);
      return false;
    } else {
      await addFavorite(item);
      return true;
    }
  }

  /// 搜索收藏
  Future<List<EntertainmentItem>> searchFavorites(String keyword) async {
    final favorites = await getFavorites();
    if (keyword.isEmpty) return favorites;
    return favorites.where((e) => e.matches(keyword)).toList();
  }

  /// 清除所有收藏
  Future<void> clearFavorites() async {
    final prefs = await _ensurePrefs;
    await prefs.remove(_keyFavorites);
  }
}
