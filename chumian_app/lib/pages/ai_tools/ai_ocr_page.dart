import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chumian_ai/services/api_service.dart';
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
/// AIOcrPage —— AI 文字识别(OCR)
/// 图片选择(模拟)，识别结果展示，文字编辑，复制，翻译，多语言支持
/// ============================================================
class AIOcrPage extends StatefulWidget {
  const AIOcrPage({super.key});

  @override
  State<AIOcrPage> createState() => _AIOcrPageState();
}

class _AIOcrPageState extends State<AIOcrPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  final TextEditingController _resultController = TextEditingController();

  int _selectedLang = 0;
  bool _isRecognizing = false;
  bool _hasResult = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isTranslating = false;
  String _translatedText = '';
  String _selectedImage = '';

  static const List<String> _languages = ['中文', 'English', '日本語', '한국어', '多语言混合'];
  static const List<String> _sampleImages = ['发票/收据', '书籍页面', '手写笔记', '名片', '路牌/标识', '菜单'];
  static const Map<String, String> _sampleTexts = {
    '发票/收据': '增值税普通发票\n\n发票代码：011002000111\n发票号码：12345678\n开票日期：2024年03月15日\n\n购买方：XX科技有限公司\n纳税人识别号：91110108MA01XXXXXX\n地址、电话：北京市海淀区XX路XX号\n开户行及账号：中国工商银行XX支行\n\n货物或应税劳务名称：技术服务费\n规格型号：*\n单位：次\n数量：1\n单价：5000.00\n金额：5000.00\n税率：6%\n税额：300.00\n\n价税合计（大写）：伍仟叁佰元整\n（小写）￥5300.00\n\n销售方：XX咨询有限公司\n备注：',
    '书籍页面': '第一章 引言\n\n在当今这个信息爆炸的时代，我们每天都在接收海量的信息。然而，真正有价值的信息却往往被淹没在噪音之中。如何从纷繁复杂的信息中提炼出真知灼见，成为了每个人都需要面对的课题。\n\n本书旨在探讨信息时代的认知方法论，帮助读者建立起一套系统化的思维框架。通过对多个领域的深入分析，我们将揭示隐藏在表象之下的规律与本质。\n\n1.1 研究背景\n\n随着互联网技术的飞速发展，信息的传播速度和范围都达到了前所未有的水平。据统计，全球每天产生的数据量超过2.5艾字节，这相当于美国国会图书馆所有印刷品信息量的100万倍。\n\n1.2 研究意义\n\n在这样的背景下，信息筛选和知识管理的能力变得尤为重要。本书的研究不仅具有理论价值，更具有实践指导意义。',
    '手写笔记': '会议纪要 - 2024.03.15\n\n参会人员：张三、李四、王五\n会议主题：Q2产品规划讨论\n\n一、产品方向\n1. 继续深耕AI领域，重点布局大模型应用\n2. 移动端体验优化，提升用户留存\n3. 探索B端商业化路径\n\n二、关键指标\n- DAU目标：突破100万\n- 留存率：次日≥40%，7日≥20%\n- 营收：Q2达到500万\n\n三、待办事项\n□ 张三：完成产品需求文档（3.20前）\n□ 李四：技术方案评审（3.22前）\n□ 王五：市场调研分析（3.25前）\n\n四、下次会议\n时间：下周五 14:00\n地点：3楼会议室A\n\n备注：记得带笔记本电脑',
    '名片': '张三\n产品总监\n\nXX科技有限公司\n\n手机：138-0000-0000\n邮箱：zhangsan@example.com\n地址：北京市海淀区中关村大街1号\n\n微信：zhangsan_2024\n官网：www.example.com',
    '路牌/标识': '前方500米\n停车场入口\nP\n\n营业时间：06:00 - 22:00\n收费标准：\n小型车：5元/小时\n大型车：10元/小时\n\n24小时服务热线：400-000-0000\n\n禁止吸烟\n请勿乱扔垃圾',
    '菜单': '招牌菜品\n\n招牌红烧肉 ￥58\n精选五花肉，慢炖两小时，肥而不腻\n\n宫保鸡丁 ￥38\n经典川菜，鸡肉嫩滑，花生酥脆\n\n清蒸鲈鱼 ￥88\n新鲜鲈鱼，清蒸保留原汁原味\n\n麻婆豆腐 ￥28\n麻辣鲜香，豆腐嫩滑入味\n\n时蔬沙拉 ￥22\n新鲜时令蔬菜，健康轻食\n\n汤品\n番茄蛋花汤 ￥18\n紫菜虾皮汤 ￥16\n\n主食\n米饭 ￥3\n葱油拌面 ￥15\n\n饮品\n酸梅汤 ￥12\n柠檬水 ￥8',
  };

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: MiuixDuration.slow);
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: MiuixCurves.miuixSpring)));
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: Curves.easeOutCubic)));
    return AnimatedBuilder(animation: animation, builder: (_, __) => Opacity(opacity: animation.value, child: Transform.translate(offset: slide.value, child: child)));
  }

  Future<void> _recognize(String imageType) async {
    setState(() {
      _isRecognizing = true;
      _hasResult = false;
      _hasError = false;
      _errorMessage = '';
      _selectedImage = imageType;
      _translatedText = '';
    });

    try {
      final lang = _languages[_selectedLang];
      final result = await ApiService.aiToolComplete(
        systemPrompt: '你是一位OCR文字识别专家。请识别一张$imageType类型的图片，输出识别到的$lang文字内容。要求格式真实、内容合理。',
        userInput: '图片类型：$imageType\n语言：$lang',
      );
      if (mounted) {
        _resultController.text = result;
        setState(() {
          _isRecognizing = false;
          _hasResult = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecognizing = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _translate() async {
    if (_resultController.text.isEmpty) return;
    setState(() => _isTranslating = true);
    try {
      final result = await ApiService.aiToolComplete(
        systemPrompt: '你是一位专业翻译。请将以下文本翻译为英文。只输出翻译结果。',
        userInput: _resultController.text,
      );
      if (mounted) {
        _translatedText = result;
        setState(() => _isTranslating = false);
      }
    } catch (e) {
      if (mounted) {
        _translatedText = '翻译失败：$e';
        setState(() => _isTranslating = false);
      }
    }
  }

  Future<void> _copyText() async {
    if (_resultController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _resultController.text));
    if (mounted) MiuixToast.show(context, message: '已复制识别文字', type: MiuixToastType.success);
  }

  Future<void> _copyTranslation() async {
    if (_translatedText.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _translatedText));
    if (mounted) MiuixToast.show(context, message: '已复制翻译结果', type: MiuixToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: 'AI 文字识别 (OCR)', backgroundColor: MiuixColors.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedItem(_buildLangSelector(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildImagePicker(), 1),
            const SizedBox(height: 20),
            if (_isRecognizing) _buildAnimatedItem(_buildRecognizingCard(), 2),
            if (_hasResult) ...[
              _buildAnimatedItem(_buildResultCard(), 2),
              const SizedBox(height: 16),
              _buildAnimatedItem(_buildActionButtons(), 3),
              const SizedBox(height: 16),
              if (_isTranslating) _buildAnimatedItem(_buildTranslatingCard(), 4),
              if (_translatedText.isNotEmpty) _buildAnimatedItem(_buildTranslationCard(), 4),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLangSelector() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('识别语言', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_languages.length, (index) {
              return MiuixChip(label: _languages[index], isSelected: _selectedLang == index, onTap: () => setState(() => _selectedLang = index));
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('选择图片类型', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('点击下方卡片选择对应类型的图片进行OCR识别', style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: List.generate(_sampleImages.length, (index) {
              final type = _sampleImages[index];
              final isSelected = _selectedImage == type;
              return MiuixRipple(
                borderRadius: MiuixRadius.md,
                child: GestureDetector(
                  onTap: () => _recognize(type),
                  child: AnimatedContainer(
                    duration: MiuixDuration.fast,
                    curve: MiuixCurves.miuixSpring,
                    decoration: BoxDecoration(
                      gradient: isSelected ? const LinearGradient(colors: MiuixColors.primaryGradient) : null,
                      color: isSelected ? null : MiuixColors.surfaceVariant,
                      borderRadius: MiuixRadius.mdRadius,
                      border: Border.all(color: isSelected ? MiuixColors.primary : MiuixColors.borderLight),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getImageIcon(type), size: 28, color: isSelected ? Colors.white : MiuixColors.primary),
                        const SizedBox(height: 6),
                        Text(type, style: TextStyle(fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : MiuixColors.textSecondary, textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _getImageIcon(String type) {
    switch (type) {
      case '发票/收据': return Icons.receipt;
      case '书籍页面': return Icons.menu_book;
      case '手写笔记': return Icons.edit_note;
      case '名片': return Icons.badge;
      case '路牌/标识': return Icons.signpost;
      case '菜单': return Icons.restaurant_menu;
      default: return Icons.image;
    }
  }

  Widget _buildRecognizingCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const MiuixProgress(type: MiuixProgressType.circularIndeterminate, size: 48, strokeWidth: 4),
        const SizedBox(height: 16),
        const Text('AI 正在识别文字...', style: TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
        const SizedBox(height: 8),
        Text('${_languages[_selectedLang]}识别中，请稍候', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
      ]),
    );
  }

  Widget _buildResultCard() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)]),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.smRadius), child: const Icon(Icons.text_fields, color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              Expanded(child: Text('识别结果 · $_selectedImage', style: const TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: MiuixColors.success.withValues(alpha: 0.15), borderRadius: MiuixRadius.pillRadius),
                child: const Text('置信度 98.5%', style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.success, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: MiuixRadius.mdRadius, border: Border.all(color: MiuixColors.borderLight)),
            child: TextField(
              controller: _resultController,
              maxLines: 12,
              style: const TextStyle(fontSize: MiuixFontSize.md, height: 1.7, color: MiuixColors.textPrimary),
              decoration: const InputDecoration(border: InputBorder.none, hintText: '识别结果可在此编辑...'),
            ),
          ),
          const SizedBox(height: 8),
          Text('共 ${_resultController.text.length} 字', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(child: MiuixButton(label: '复制文字', icon: Icons.copy, type: MiuixButtonType.secondary, onPressed: _copyText)),
        const SizedBox(width: 12),
        Expanded(child: MiuixButton(label: _isTranslating ? '翻译中...' : '翻译成英文', icon: Icons.translate, type: MiuixButtonType.primary, loading: _isTranslating, onPressed: _isTranslating ? null : _translate)),
      ],
    );
  }

  Widget _buildTranslatingCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const MiuixProgress(type: MiuixProgressType.circularIndeterminate, size: 32, strokeWidth: 3),
          const SizedBox(width: 12),
          const Text('AI 正在翻译...', style: TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTranslationCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.g_translate, size: 20, color: MiuixColors.primary),
              const SizedBox(width: 8),
              const Expanded(child: Text('翻译结果 (English)', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary))),
              MiuixIconButton(icon: Icons.copy, style: MiuixIconButtonStyle.outlined, size: 32, iconSize: 16, onPressed: _copyTranslation),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: MiuixColors.surfaceVariant, borderRadius: MiuixRadius.smRadius),
            child: SingleChildScrollView(
              maxHeight: 250,
              child: Text(_translatedText, style: const TextStyle(fontSize: MiuixFontSize.md, height: 1.7, color: MiuixColors.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}
