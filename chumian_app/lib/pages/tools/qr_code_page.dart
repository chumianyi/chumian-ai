import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_segment.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// QRCodePage —— 二维码工具
/// 生成二维码(文本/URL)，粉色主题，保存分享，扫码入口(模拟)
/// ============================================================
class QRCodePage extends StatefulWidget {
  const QRCodePage({super.key});

  @override
  State<QRCodePage> createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  final TextEditingController _textController = TextEditingController();
  int _selectedType = 0;
  bool _hasGenerated = false;

  static const List<String> _types = ['文本', 'URL', 'WiFi', '名片'];
  static const List<IconData> _typeIcons = [
    Icons.text_fields,
    Icons.link,
    Icons.wifi,
    Icons.contact_page,
  ];

  static const List<String> _samples = [
    'https://chumian.ai',
    '初眠AI - 你的智能助手',
    'Hello World!',
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.07, (index * 0.07) + 0.4,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.07, (index * 0.07) + 0.4,
            curve: Curves.easeOutCubic),
      ),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) => Opacity(
        opacity: anim.value,
        child: Transform.translate(offset: slide.value, child: child),
      ),
    );
  }

  void _generate() {
    if (_textController.text.trim().isEmpty) {
      MiuixToast.show(context,
          message: '请输入内容', type: MiuixToastType.warning);
      return;
    }
    setState(() => _hasGenerated = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '二维码工具',
        backgroundColor: MiuixColors.background,
        actions: [
          MiuixIconButton(
            icon: Icons.qr_code_scanner,
            style: MiuixIconButtonStyle.ghost,
            onPressed: () {
              MiuixToast.show(context,
                  message: '打开扫码功能', type: MiuixToastType.info);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildAnimatedItem(_buildTypeSelector(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildInputSection(), 1),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildGenerateButton(), 2),
            const SizedBox(height: 20),
            if (_hasGenerated) _buildAnimatedItem(_buildQRDisplay(), 3),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return MiuixSegmentControl(
      items: List.generate(
        _types.length,
        (index) => MiuixSegmentItem(
          label: _types[index],
          icon: _typeIcons[index],
        ),
      ),
      selectedIndex: _selectedType,
      onChanged: (i) => setState(() => _selectedType = i),
    );
  }

  Widget _buildInputSection() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_types[_selectedType]}内容',
            style: const TextStyle(
              fontSize: MiuixFontSize.md,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          MiuixInput(
            controller: _textController,
            hintText: _getHintText(),
            prefixIcon: _typeIcons[_selectedType],
            maxLines: _selectedType == 0 ? 4 : 1,
            minLines: _selectedType == 0 ? 2 : 1,
            type: _selectedType == 0
                ? MiuixInputType.multiline
                : MiuixInputType.text,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_samples.length, (index) {
              return MiuixChip(
                label: _samples[index],
                onTap: () => _textController.text = _samples[index],
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getHintText() {
    switch (_selectedType) {
      case 0:
        return '输入要生成二维码的文本...';
      case 1:
        return '输入网址，如 https://example.com';
      case 2:
        return '输入WiFi名称:密码';
      case 3:
        return '输入姓名:电话:邮箱';
      default:
        return '输入内容...';
    }
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: '生成二维码',
        icon: Icons.qr_code,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        onPressed: _generate,
      ),
    );
  }

  Widget _buildQRDisplay() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 模拟二维码
          Container(
            width: 220,
            height: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: MiuixRadius.lgRadius,
              boxShadow: MiuixShadows.sm,
            ),
            child: CustomPaint(
              painter: _QRCodePainter(seed: _textController.text.hashCode),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _textController.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: MiuixFontSize.md,
              color: MiuixColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '类型：${_types[_selectedType]}',
            style: const TextStyle(
              fontSize: MiuixFontSize.sm,
              color: MiuixColors.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: MiuixButton(
                  label: '保存',
                  icon: Icons.download,
                  type: MiuixButtonType.secondary,
                  onPressed: () {
                    MiuixToast.show(context,
                        message: '二维码已保存', type: MiuixToastType.success);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MiuixButton(
                  label: '分享',
                  icon: Icons.share,
                  type: MiuixButtonType.primary,
                  onPressed: () {
                    MiuixToast.show(context,
                        message: '分享链接已复制', type: MiuixToastType.success);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 模拟二维码绘制器
class _QRCodePainter extends CustomPainter {
  final int seed;
  _QRCodePainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final cellSize = size.width / 25;
    final paint = Paint()..color = MiuixColors.primaryDeep;

    // 绘制定位角（三个大方块）
    _drawFinderPattern(canvas, paint, 0, 0, cellSize);
    _drawFinderPattern(canvas, paint, 18, 0, cellSize);
    _drawFinderPattern(canvas, paint, 0, 18, cellSize);

    // 绘制随机数据点
    for (int i = 0; i < 25; i++) {
      for (int j = 0; j < 25; j++) {
        // 跳过定位角区域
        if ((i < 7 && j < 7) ||
            (i > 17 && j < 7) ||
            (i < 7 && j > 17)) {
          continue;
        }
        if (random.nextBool()) {
          canvas.drawRect(
            Rect.fromLTWH(
              i * cellSize,
              j * cellSize,
              cellSize * 0.9,
              cellSize * 0.9,
            ),
            paint,
          );
        }
      }
    }
  }

  void _drawFinderPattern(
      Canvas canvas, Paint paint, int x, int y, double cellSize) {
    // 外框
    final outerPaint = Paint()..color = MiuixColors.primaryDeep;
    canvas.drawRect(
      Rect.fromLTWH(x * cellSize, y * cellSize, cellSize * 7, cellSize * 7),
      outerPaint,
    );
    // 内白
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(
          (x + 1) * cellSize, (y + 1) * cellSize, cellSize * 5, cellSize * 5),
      whitePaint,
    );
    // 中心
    canvas.drawRect(
      Rect.fromLTWH(
          (x + 2) * cellSize, (y + 2) * cellSize, cellSize * 3, cellSize * 3),
      outerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is! _QRCodePainter || oldDelegate.seed != seed;
}
