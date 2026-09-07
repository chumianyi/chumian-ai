import 'package:flutter/material.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_chip.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_progress.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';

/// ============================================================
/// AINameGeneratorPage —— AI 起名
/// 类型(人名/网名/品牌名/宠物名/游戏名)，性别，风格，字数
/// 生成多个名字，含义解释，复制
/// ============================================================
class AINameGeneratorPage extends StatefulWidget {
  const AINameGeneratorPage({super.key});

  @override
  State<AINameGeneratorPage> createState() => _AINameGeneratorPageState();
}

class _AINameGeneratorPageState extends State<AINameGeneratorPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _keywordController = TextEditingController();

  int _selectedType = 0;
  int _selectedGender = 0;
  int _selectedStyle = 0;
  int _nameLength = 2;
  bool _isGenerating = false;
  bool _hasResult = false;
  bool _hasError = false;
  String _errorMessage = \'\';
  List<Map<String, String>> _names = [];

  static const List<String> _types = ['人名', '网名', '品牌名', '宠物名', '游戏名'];
  static const List<IconData> _typeIcons = [Icons.person, Icons.alternate_email, Icons.business, Icons.pets, Icons.sports_esports];
  static const List<String> _genders = ['中性', '男生', '女生'];
  static const List<String> _styles = ['古风', '现代', '文艺', '可爱', '霸气'];
  static const List<String> _sampleKeywords = ['月', '风', '花', '雪', '星辰', '粉色'];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: MiuixDuration.slow);
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _surnameController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: MiuixCurves.miuixSpring)));
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: Curves.easeOutCubic)));
    return AnimatedBuilder(animation: animation, builder: (_, __) => Opacity(opacity: animation.value, child: Transform.translate(offset: slide.value, child: child)));
  }

  Future<void> _generateNames() async {
    setState(() {
      _isGenerating = true;
      _hasResult = false;
      _names = [];
    });
    try {
      final result = await ApiService.aiToolComplete(
        systemPrompt: '你是一位起名专家。请根据用户提供的姓氏、性别和风格偏好，生成10个寓意美好的名字，并附上寓意解释，每个名字一行。',
        userInput: "姓氏："+_surnameController.text+"\n性别："+_genders[_selectedGender]+"\n风格："+_styles[_selectedStyle],
      );
      if (mounted) {
        _names = result.split('\n').where((l) => l.trim().isNotEmpty).toList();
        setState(() {
          _isGenerating = false;
          _hasResult = true;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  List<Map<String, String>> _buildNameList() {
    final type = _types[_selectedType];
    final gender = _genders[_selectedGender];
    final style = _styles[_selectedStyle];
    final surname = _surnameController.text.trim();
    final keyword = _keywordController.text.trim();

    Map<String, List<Map<String, String>>> pool = {
      '古风': [
        {'name': '${surname}墨言', 'meaning': '墨香四溢，言而有信，寓意文采斐然、为人正直。'},
        {'name': '${surname}清欢', 'meaning': '人间有味是清欢，寓意淡泊宁静、知足常乐。'},
        {'name': '${surname}疏影', 'meaning': '疏影横斜水清浅，寓意清雅脱俗、风姿绰约。'},
        {'name': '${surname}长歌', 'meaning': '对酒当歌，人生几何，寓意豪迈洒脱、才情出众。'},
        {'name': '${surname}绾青', 'meaning': '青丝绾正，寓意温柔细腻、情深意重。'},
        {'name': '${surname}砚秋', 'meaning': '砚田耕秋，寓意勤奋好学、收获满满。'},
      ],
      '现代': [
        {'name': '${surname}子轩', 'meaning': '气宇轩昂，寓意风度翩翩、志向远大。'},
        {'name': '${surname}思远', 'meaning': '思深忧远，寓意深思熟虑、目光长远。'},
        {'name': '${surname}语桐', 'meaning': '凤栖梧桐，寓意才华出众、品格高洁。'},
        {'name': '${surname}晨曦', 'meaning': '清晨的第一缕阳光，寓意希望与新生。'},
        {'name': '${surname}一诺', 'meaning': '一诺千金，寓意诚实守信、值得信赖。'},
        {'name': '${surname}沐辰', 'meaning': '沐浴星辰，寓意前程似锦、光彩照人。'},
      ],
      '文艺': [
        {'name': '${surname}诗涵', 'meaning': '如诗如画，涵泳优游，寓意才情与涵养兼备。'},
        {'name': '${surname}书瑶', 'meaning': '书香门第，瑶林琼树，寓意文雅高贵。'},
        {'name': '${surname}知夏', 'meaning': '知夏而安，寓意感知美好、安然自在。'},
        {'name': '${surname}慕白', 'meaning': '向往清白，寓意品行高洁、胸怀坦荡。'},
        {'name': '${surname}听澜', 'meaning': '静听波澜，寓意从容淡定、内心丰盈。'},
        {'name': '${surname}望舒', 'meaning': '前望舒使先驱兮，寓意追求光明、引领前行。'},
      ],
      '可爱': [
        {'name': '${surname}糖糖', 'meaning': '甜蜜如糖，寓意生活甜美、惹人喜爱。'},
        {'name': '${surname}朵朵', 'meaning': '花朵朵朵，寓意活泼可爱、生机盎然。'},
        {'name': '${surname}奶团', 'meaning': '软糯香甜，寓意呆萌可爱、让人想rua。'},
        {'name': '${surname}桃桃', 'meaning': '蜜桃甜甜，寓意粉嫩可爱、元气满满。'},
        {'name': '${surname}糯米', 'meaning': '黏糯香甜，寓意温柔黏人、可爱至极。'},
        {'name': '${surname}啾啾', 'meaning': '小鸟啾鸣，寓意灵动活泼、声音悦耳。'},
      ],
      '霸气': [
        {'name': '${surname}凌天', 'meaning': '凌驾天际，寓意志存高远、气势磅礴。'},
        {'name': '${surname}战野', 'meaning': '战于荒野，寓意勇猛无畏、所向披靡。'},
        {'name': '${surname}苍穹', 'meaning': '苍穹浩瀚，寓意胸怀天下、气度不凡。'},
        {'name': '${surname}裂空', 'meaning': '撕裂长空，寓意突破极限、一鸣惊人。'},
        {'name': '${surname}独尊', 'meaning': '唯我独尊，寓意自信强大、独一无二。'},
        {'name': '${surname}逆鳞', 'meaning': '龙有逆鳞，触之必怒，寓意有底线、不可侵犯。'},
      ],
    };

    var list = pool[style] ?? pool['现代']!;
    if (type == '网名') {
      list = list.map((e) => {'name': '${e['name']}°', 'meaning': e['meaning']!}).toList();
    } else if (type == '品牌名') {
      list = [
        {'name': '${surname}${keyword}集', 'meaning': '汇聚美好，寓意品牌包罗万象、品质上乘。'},
        {'name': '${keyword}里', 'meaning': '方寸之间，自有天地，寓意品牌精致有格调。'},
        {'name': '${surname}物社', 'meaning': '好物之社，寓意品牌专注品质、用心造物。'},
        {'name': '${keyword}光', 'meaning': '一束光的温暖，寓意品牌带来希望与美好。'},
        {'name': '${surname}研物', 'meaning': '精研好物，寓意品牌匠心独运、精益求精。'},
        {'name': '${keyword}间', 'meaning': '美好空间，寓意品牌营造舒适体验。'},
      ];
    } else if (type == '宠物名') {
      list = [
        {'name': '团子', 'meaning': '圆滚滚的一团，寓意宠物可爱圆润、讨人喜欢。'},
        {'name': '奶茶', 'meaning': '香甜温暖，寓意宠物像奶茶一样治愈人心。'},
        {'name': '布丁', 'meaning': 'Q弹可爱，寓意宠物活泼好动、萌态百出。'},
        {'name': '年糕', 'meaning': '黏黏甜甜，寓意宠物黏人可爱、生活甜蜜。'},
        {'name': '棉花糖', 'meaning': '柔软蓬松，寓意宠物毛发柔软、性格温柔。'},
        {'name': '小粉', 'meaning': '粉嫩可爱，寓意宠物颜值高、少女心满满。'},
      ];
    } else if (type == '游戏名') {
      list = [
        {'name': '夜刃', 'meaning': '夜色中的利刃，寓意游戏中身手敏捷、一击必杀。'},
        {'name': '霜火', 'meaning': '冰霜与烈焰交织，寓意技能华丽、伤害爆炸。'},
        {'name': '孤影', 'meaning': '孤独的影子，寓意独来独往、神秘强大。'},
        {'name': '星陨', 'meaning': '星辰陨落，寓意大招毁天灭地、气势恢宏。'},
        {'name': '幻梦', 'meaning': '虚幻梦境，寓意技能迷惑敌人、变幻莫测。'},
        {'name': '龙裔', 'meaning': '龙族后裔，寓意出身尊贵、潜力无限。'},
      ];
    }

    if (keyword.isNotEmpty && type == '人名') {
      list = list.map((e) => {'name': e['name']!.replaceAll(surname, surname + keyword.substring(0, 1)), 'meaning': e['meaning']!}).toList();
    }

    return list.take(6).toList();
  }

  Future<void> _copyName(String name) async {
    await Clipboard.setData(ClipboardData(text: name));
    if (mounted) MiuixToast.show(context, message: '已复制名字', type: MiuixToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: 'AI 起名', backgroundColor: MiuixColors.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedItem(_buildTypeSelector(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildGenderStyleRow(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildInputCard(), 2),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildGenerateButton(), 3),
            const SizedBox(height: 20),
            if (_isGenerating) _buildAnimatedItem(_buildLoadingCard(), 4),
            if (_hasError) _buildAnimatedItem(_buildErrorCard(), 5),

            if (_hasResult) _buildAnimatedItem(_buildResultList(), 4),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('名字类型', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_types.length, (index) {
              final isSelected = _selectedType == index;
              return MiuixRipple(
                borderRadius: MiuixRadius.md,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedType = index),
                  child: AnimatedContainer(
                    duration: MiuixDuration.fast,
                    curve: MiuixCurves.miuixSpring,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected ? const LinearGradient(colors: MiuixColors.primaryGradient) : null,
                      color: isSelected ? null : MiuixColors.surfaceVariant,
                      borderRadius: MiuixRadius.mdRadius,
                      boxShadow: isSelected ? MiuixShadows.sm : null,
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_typeIcons[index], size: 18, color: isSelected ? Colors.white : MiuixColors.primary),
                      const SizedBox(width: 6),
                      Text(_types[index], style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : MiuixColors.textSecondary)),
                    ]),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderStyleRow() {
    return Row(
      children: [
        Expanded(
          child: MiuixCard(
            style: MiuixCardStyle.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('性别', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(_genders.length, (index) {
                    return MiuixChip(label: _genders[index], isSelected: _selectedGender == index, onTap: () => setState(() => _selectedGender = index), height: 30);
                  }),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MiuixCard(
            style: MiuixCardStyle.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('风格', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(_styles.length, (index) {
                    return MiuixChip(label: _styles[index], isSelected: _selectedStyle == index, onTap: () => setState(() => _selectedStyle = index), height: 30);
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MiuixInput(controller: _surnameController, hintText: '姓氏/前缀（选填）', prefixIcon: Icons.text_fields),
          const SizedBox(height: 12),
          MiuixInput(controller: _keywordController, hintText: '喜欢的字/关键词（选填）', prefixIcon: Icons.tag),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_sampleKeywords.length, (index) {
              return MiuixChip(label: _sampleKeywords[index], onTap: () => _keywordController.text = _sampleKeywords[index], style: MiuixChipStyle.normal);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isGenerating ? '生成中...' : '开始起名',
        icon: Icons.auto_awesome,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isGenerating,
        onPressed: _isGenerating ? null : _generateNames,
      ),
    );
  }

  Widget _buildLoadingCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const MiuixProgress(type: MiuixProgressType.circularIndeterminate, size: 48, strokeWidth: 4),
        const SizedBox(height: 16),
        Text('AI 正在翻阅字典...', style: const TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
        const SizedBox(height: 8),
        Text('${_styles[_selectedStyle]}风格${_types[_selectedType]}创作中', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
      ]),
    );
  }

  Widget _buildResultList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(left: 4, bottom: 12), child: Text('推荐名字', style: TextStyle(fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w700, color: MiuixColors.textPrimary))),
        ...List.generate(_names.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MiuixCard(
              style: MiuixCardStyle.gradient,
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)]),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.mdRadius),
                    child: Center(child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_names[index]['name']!, style: const TextStyle(fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w700, color: MiuixColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(_names[index]['meaning']!, style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textSecondary, height: 1.5)),
                      ],
                    ),
                  ),
                  MiuixIconButton(icon: Icons.copy, style: MiuixIconButtonStyle.outlined, size: 36, iconSize: 18, onPressed: () => _copyName(_names[index]['name']!)),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: MiuixButton(label: '换一批', icon: Icons.refresh, type: MiuixButtonType.secondary, onPressed: _generateNames)),
      ],
    );

  /// 错误状态卡片（请求失败时显示，含重试按钮）
  Widget _buildErrorCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: MiuixColors.error, size: 48),
          const SizedBox(height: 12),
          Text('生成失败', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.error)),
          const SizedBox(height: 8),
          Text(_errorMessage, style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          MiuixButton(
            label: '重试',
            icon: Icons.refresh,
            type: MiuixButtonType.gradient,
            gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
            onPressed: () => setState(() => _hasError = false),
          ),
        ],
      ),
    );
  }

  }
}
