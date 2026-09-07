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
/// AIWorkoutPage —— AI 健身计划
/// 目标(增肌/减脂/塑形/康复)，部位，天数，难度，器械选择
/// 生成训练计划(动作+组数+休息)，进度跟踪
/// ============================================================
class AIWorkoutPage extends StatefulWidget {
  const AIWorkoutPage({super.key});

  @override
  State<AIWorkoutPage> createState() => _AIWorkoutPageState();
}

class _AIWorkoutPageState extends State<AIWorkoutPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  int _selectedGoal = 1;
  int _selectedPart = 0;
  int _selectedDays = 3;
  int _selectedDifficulty = 1;
  int _selectedEquipment = 0;
  bool _isGenerating = false;
  bool _hasResult = false;
  bool _hasError = false;
  String _errorMessage = \'\';
  List<Map<String, dynamic>> _plan = [];
  final Set<String> _completed = {};

  static const List<String> _goals = ['增肌', '减脂', '塑形', '康复'];
  static const List<IconData> _goalIcons = [Icons.fitness_center, Icons.local_fire_department, Icons.accessibility_new, Icons.healing];
  static const List<String> _parts = ['全身', '胸肩', '背臂', '腿部', '核心', '臀腿'];
  static const List<String> _difficulties = ['入门', '进阶', '高级'];
  static const List<String> _equipments = ['无器械', '哑铃', '健身房全套'];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: MiuixDuration.slow);
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: MiuixCurves.miuixSpring)));
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: Curves.easeOutCubic)));
    return AnimatedBuilder(animation: animation, builder: (_, __) => Opacity(opacity: animation.value, child: Transform.translate(offset: slide.value, child: child)));
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isGenerating = true;
      _hasResult = false;
      _plan = [];
      _completed.clear();
    });
    try {
      final result = await ApiService.aiToolComplete(
        systemPrompt: '你是一位专业的健身教练。请根据用户提供的身体数据和健身目标，生成一份科学合理的训练计划，包含训练动作、组数次数和注意事项。',
        userInput: "目标："+_goals[_selectedGoal]+"\n水平："+_levels[_selectedLevel]+"\n每周训练："+_daysPerWeek.toString()+"天",
      );
      if (mounted) {
        _planText = result;
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

  void _toggleExercise(String key) {
    setState(() {
      if (_completed.contains(key)) {
        _completed.remove(key);
      } else {
        _completed.add(key);
        MiuixToast.show(context, message: '完成！继续加油', type: MiuixToastType.success);
      }
    });
  }

  double get _progress {
    int total = 0;
    for (var day in _plan) {
      total += (day['exercises'] as List).length;
    }
    return total == 0 ? 0 : _completed.length / total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: 'AI 健身计划', backgroundColor: MiuixColors.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedItem(_buildGoalSelector(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildPartSelector(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildSettingsRow(), 2),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildGenerateButton(), 3),
            const SizedBox(height: 20),
            if (_isGenerating) _buildAnimatedItem(_buildLoadingCard(), 4),
            if (_hasError) _buildAnimatedItem(_buildErrorCard(), 5),

            if (_hasResult) ...[
              _buildAnimatedItem(_buildProgressCard(), 4),
              const SizedBox(height: 16),
              ..._buildDayCards(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSelector() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('训练目标', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_goals.length, (index) {
              final isSelected = _selectedGoal == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 3 ? 6 : 0),
                  child: MiuixRipple(
                    borderRadius: MiuixRadius.md,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedGoal = index),
                      child: AnimatedContainer(
                        duration: MiuixDuration.fast,
                        curve: MiuixCurves.miuixSpring,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected ? const LinearGradient(colors: MiuixColors.primaryGradient) : null,
                          color: isSelected ? null : MiuixColors.surfaceVariant,
                          borderRadius: MiuixRadius.mdRadius,
                          boxShadow: isSelected ? MiuixShadows.sm : null,
                        ),
                        child: Column(
                          children: [
                            Icon(_goalIcons[index], size: 20, color: isSelected ? Colors.white : MiuixColors.primary),
                            const SizedBox(height: 4),
                            Text(_goals[index], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : MiuixColors.textSecondary)),
                          ],
                        ),
                      ),
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

  Widget _buildPartSelector() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('训练部位', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_parts.length, (index) {
              return MiuixChip(label: _parts[index], isSelected: _selectedPart == index, onTap: () => setState(() => _selectedPart = index));
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow() {
    return Row(
      children: [
        Expanded(
          child: MiuixCard(
            style: MiuixCardStyle.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('训练天数', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _dayButton(2),
                    _dayButton(3),
                    _dayButton(4),
                    _dayButton(5),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('难度', style: TextStyle(fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w600, color: MiuixColors.textSecondary)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, children: List.generate(_difficulties.length, (i) => MiuixChip(label: _difficulties[i], isSelected: _selectedDifficulty == i, onTap: () => setState(() => _selectedDifficulty = i), height: 28))),
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
                const Text('器械条件', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
                const SizedBox(height: 10),
                Column(
                  children: List.generate(_equipments.length, (index) {
                    final isSelected = _selectedEquipment == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: MiuixRipple(
                        borderRadius: MiuixRadius.sm,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedEquipment = index),
                          child: AnimatedContainer(
                            duration: MiuixDuration.fast,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected ? const LinearGradient(colors: MiuixColors.primaryGradient) : null,
                              color: isSelected ? null : MiuixColors.surfaceVariant,
                              borderRadius: MiuixRadius.smRadius,
                            ),
                            child: Row(
                              children: [
                                Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: isSelected ? Colors.white : MiuixColors.textTertiary),
                                const SizedBox(width: 6),
                                Text(_equipments[index], style: TextStyle(fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : MiuixColors.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dayButton(int days) {
    final isSelected = _selectedDays == days;
    return MiuixRipple(
      borderRadius: MiuixRadius.sm,
      child: GestureDetector(
        onTap: () => setState(() => _selectedDays = days),
        child: AnimatedContainer(
          duration: MiuixDuration.fast,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: isSelected ? const LinearGradient(colors: MiuixColors.primaryGradient) : null,
            color: isSelected ? null : MiuixColors.surfaceVariant,
            borderRadius: MiuixRadius.smRadius,
          ),
          child: Center(child: Text('$days', style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? Colors.white : MiuixColors.textSecondary))),
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isGenerating ? '生成中...' : '生成训练计划',
        icon: Icons.fitness_center,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isGenerating,
        onPressed: _isGenerating ? null : _generatePlan,
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
        const Text('AI 正在制定计划...', style: TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
        const SizedBox(height: 8),
        Text('${_goals[_selectedGoal]} · ${_parts[_selectedPart]} · ${_difficulties[_selectedDifficulty]}', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
      ]),
    );
  }

  Widget _buildProgressCard() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)]),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('训练进度', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
              Text('${(_progress * 100).toInt()}%', style: const TextStyle(fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w700, color: MiuixColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: MiuixRadius.pillRadius,
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 10,
              backgroundColor: MiuixColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation(MiuixColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text('已完成 ${_completed.length} 个动作', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textSecondary)),
        ],
      ),
    );
  }

  List<Widget> _buildDayCards() {
    return List.generate(_plan.length, (dayIndex) {
      final day = _plan[dayIndex];
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildAnimatedItem(
          MiuixCard(
            style: MiuixCardStyle.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.mdRadius),
                      child: Center(child: Text('D${day['day']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(day['title'], style: const TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary))),
                    Text('约${day['calories']}千卡', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.directions_run, '热身', day['warmup']),
                const SizedBox(height: 8),
                ...List.generate((day['exercises'] as List).length, (exIndex) {
                  final ex = day['exercises'][exIndex];
                  final key = 'day${day['day']}_ex$exIndex';
                  final isDone = _completed.contains(key);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MiuixRipple(
                      borderRadius: MiuixRadius.sm,
                      child: GestureDetector(
                        onTap: () => _toggleExercise(key),
                        child: AnimatedContainer(
                          duration: MiuixDuration.fast,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDone ? MiuixColors.surfaceVariant : MiuixColors.surface,
                            borderRadius: MiuixRadius.smRadius,
                            border: Border.all(color: isDone ? MiuixColors.primaryLight : MiuixColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  gradient: isDone ? const LinearGradient(colors: MiuixColors.primaryGradient) : null,
                                  border: isDone ? null : Border.all(color: MiuixColors.border),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: isDone ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ex['name'], style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: isDone ? MiuixColors.textTertiary : MiuixColors.textPrimary, decoration: isDone ? TextDecoration.lineThrough : null)),
                                    const SizedBox(height: 2),
                                    Text('${ex['sets']}组 × ${ex['reps']} · 休息${ex['rest']}', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
                                    const SizedBox(height: 2),
                                    Text(ex['note'], style: const TextStyle(fontSize: 11, color: MiuixColors.textTertiary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.self_improvement, '放松', day['cooldown']),
              ],
            ),
          ),
          dayIndex + 5,
        ),
      );
    });
  }

  Widget _buildInfoRow(IconData icon, String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: MiuixColors.primary),
        const SizedBox(width: 8),
        Text('$label：', style: const TextStyle(fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w600, color: MiuixColors.textSecondary)),
        Expanded(child: Text(text, style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary))),
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
