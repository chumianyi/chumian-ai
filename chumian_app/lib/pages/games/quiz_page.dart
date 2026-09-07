import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_chip.dart';
import 'package:chumian_ai/widgets/miuix/miuix_progress.dart';
import 'package:chumian_ai/widgets/miuix/miuix_segment.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';

/// ============================================================
/// QuizPage —— 知识问答
/// 题目卡片，4选1，倒计时，分数
/// 题目分类(常识/科学/历史/娱乐)，进度条，结果页，粉色主题
/// ============================================================
class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  int _category = 0; // 0=全部, 1=常识, 2=科学, 3=历史, 4=娱乐
  bool _quizStarted = false;
  bool _quizFinished = false;

  late List<QuizQuestion> _questions;
  int _currentIndex = 0;
  int _score = 0;
  int _selectedAnswer = -1;
  bool _answered = false;
  int _timeLeft = 15;
  Timer? _timer;

  static const List<String> _categories = ['全部', '常识', '科学', '历史', '娱乐'];

  static final List<QuizQuestion> _allQuestions = [
    // 常识
    QuizQuestion(category: 1, question: '一年有多少天？', answers: ['365天', '366天', '360天', '355天'], correctIndex: 0),
    QuizQuestion(category: 1, question: '水的化学式是什么？', answers: ['CO2', 'H2O', 'O2', 'NaCl'], correctIndex: 1),
    QuizQuestion(category: 1, question: '中国的首都是哪里？', answers: ['上海', '广州', '北京', '深圳'], correctIndex: 2),
    QuizQuestion(category: 1, question: '一周有几天？', answers: ['5天', '6天', '7天', '8天'], correctIndex: 2),
    QuizQuestion(category: 1, question: '人体最大的器官是什么？', answers: ['心脏', '肝脏', '皮肤', '肺'], correctIndex: 2),
    // 科学
    QuizQuestion(category: 2, question: '光在真空中的速度约为？', answers: ['30万公里/秒', '15万公里/秒', '50万公里/秒', '10万公里/秒'], correctIndex: 0),
    QuizQuestion(category: 2, question: 'DNA的中文全称是？', answers: ['脱氧核糖核酸', '核糖核酸', '氨基酸', '蛋白质'], correctIndex: 0),
    QuizQuestion(category: 2, question: '太阳系中最大的行星是？', answers: ['地球', '土星', '木星', '火星'], correctIndex: 2),
    QuizQuestion(category: 2, question: '元素周期表中第一个元素是？', answers: ['氦', '氢', '氧', '碳'], correctIndex: 1),
    QuizQuestion(category: 2, question: '牛顿第一定律又称为什么？', answers: ['加速度定律', '惯性定律', '作用力定律', '万有引力定律'], correctIndex: 1),
    // 历史
    QuizQuestion(category: 3, question: '中华人民共和国成立于哪一年？', answers: ['1945年', '1949年', '1950年', '1912年'], correctIndex: 1),
    QuizQuestion(category: 3, question: '秦始皇统一六国是在哪一年？', answers: ['公元前221年', '公元前202年', '公元前256年', '公元前230年'], correctIndex: 0),
    QuizQuestion(category: 3, question: '唐朝的开国皇帝是谁？', answers: ['李世民', '李渊', '李隆基', '李治'], correctIndex: 1),
    QuizQuestion(category: 3, question: '第一次世界大战爆发于哪一年？', answers: ['1912年', '1914年', '1918年', '1939年'], correctIndex: 1),
    QuizQuestion(category: 3, question: '郑和下西洋发生在哪个朝代？', answers: ['宋朝', '元朝', '明朝', '清朝'], correctIndex: 2),
    // 娱乐
    QuizQuestion(category: 4, question: '《西游记》中孙悟空的武器是？', answers: ['青龙偃月刀', '如意金箍棒', '方天画戟', '九齿钉耙'], correctIndex: 1),
    QuizQuestion(category: 4, question: '电影《泰坦尼克号》的导演是？', answers: ['斯皮尔伯格', '卡梅隆', '诺兰', '昆汀'], correctIndex: 1),
    QuizQuestion(category: 4, question: '贝多芬是哪国作曲家？', answers: ['奥地利', '德国', '法国', '意大利'], correctIndex: 1),
    QuizQuestion(category: 4, question: '《红楼梦》的作者是？', answers: ['罗贯中', '施耐庵', '曹雪芹', '吴承恩'], correctIndex: 2),
    QuizQuestion(category: 4, question: 'NBA中被称为"飞人"的是？', answers: ['科比', '乔丹', '詹姆斯', '奥尼尔'], correctIndex: 1),
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
    _timer?.cancel();
    super.dispose();
  }

  void _startQuiz() {
    final filtered = _category == 0
        ? _allQuestions
        : _allQuestions.where((q) => q.category == _category).toList();
    filtered.shuffle(Random());
    _questions = filtered.take(10).toList();
    _currentIndex = 0;
    _score = 0;
    _selectedAnswer = -1;
    _answered = false;
    _quizStarted = true;
    _quizFinished = false;
    _startTimer();
    setState(() {});
  }

  void _startTimer() {
    _timeLeft = 15;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _timer?.cancel();
          _answered = true;
          _selectedAnswer = -1;
        }
      });
    });
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    _timer?.cancel();
    setState(() {
      _selectedAnswer = index;
      _answered = true;
    });
    if (index == _questions[_currentIndex].correctIndex) {
      _score += 10 + _timeLeft; // 时间奖励
    }
  }

  void _nextQuestion() {
    if (_currentIndex >= _questions.length - 1) {
      _quizFinished = true;
      _timer?.cancel();
      MiuixToast.show(context, '答题完成！得分 $_score', icon: Icons.emoji_events);
    } else {
      _currentIndex++;
      _selectedAnswer = -1;
      _answered = false;
      _startTimer();
    }
    setState(() {});
  }

  void _backToMenu() {
    _timer?.cancel();
    setState(() {
      _quizStarted = false;
      _quizFinished = false;
    });
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.06, (index * 0.06) + 0.4,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.06, (index * 0.06) + 0.4,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '知识问答',
        actions: _quizStarted
            ? [
                IconButton(
                  icon: const Icon(Icons.close, color: MiuixColors.primary),
                  onPressed: _backToMenu,
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: _quizFinished
            ? _buildResultPage()
            : (_quizStarted ? _buildQuizContent() : _buildMenu()),
      ),
    );
  }

  Widget _buildMenu() {
    return Column(
      children: [
        _buildAnimatedItem(
          MiuixCard(
            style: MiuixCardStyle.gradient,
            gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
            child: const Column(
              children: [
                Icon(Icons.quiz, color: Colors.white, size: 48),
                SizedBox(height: MiuixSpacing.md),
                Text('知识问答',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: MiuixFontSize.xxl,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: MiuixSpacing.xs),
                Text('10道题，每题15秒，答对有时间奖励',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          0,
        ),
        const SizedBox(height: MiuixSpacing.xl),
        _buildAnimatedItem(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('选择题库',
                  style: TextStyle(
                      fontSize: MiuixFontSize.lg,
                      fontWeight: FontWeight.w600,
                      color: MiuixColors.textPrimary)),
              const SizedBox(height: MiuixSpacing.md),
              Wrap(
                spacing: MiuixSpacing.sm,
                runSpacing: MiuixSpacing.sm,
                children: List.generate(_categories.length, (i) {
                  return MiuixChip(
                    label: _categories[i],
                    selected: _category == i,
                    onTap: () => setState(() => _category = i),
                  );
                }),
              ),
            ],
          ),
          1,
        ),
        const SizedBox(height: MiuixSpacing.xxl),
        _buildAnimatedItem(
          MiuixButton(
            label: '开始答题',
            icon: Icons.play_arrow,
            width: double.infinity,
            onPressed: _startQuiz,
          ),
          2,
        ),
      ],
    );
  }

  Widget _buildQuizContent() {
    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Column(
      children: [
        _buildAnimatedItem(_buildProgressBar(progress), 0),
        const SizedBox(height: MiuixSpacing.lg),
        _buildAnimatedItem(_buildTimerAndScore(), 1),
        const SizedBox(height: MiuixSpacing.lg),
        _buildAnimatedItem(_buildQuestionCard(q), 2),
        const SizedBox(height: MiuixSpacing.lg),
        ...List.generate(4, (i) => Padding(
              padding: const EdgeInsets.only(bottom: MiuixSpacing.sm),
              child: _buildAnimatedItem(_buildAnswerButton(q, i), 3 + i),
            )),
        if (_answered)
          _buildAnimatedItem(
            Padding(
              padding: const EdgeInsets.only(top: MiuixSpacing.md),
              child: MiuixButton(
                label: _currentIndex >= _questions.length - 1 ? '查看结果' : '下一题',
                icon: Icons.arrow_forward,
                width: double.infinity,
                onPressed: _nextQuestion,
              ),
            ),
            7,
          ),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('第 ${_currentIndex + 1}/${_questions.length} 题',
                style: const TextStyle(
                    color: MiuixColors.textSecondary,
                    fontSize: MiuixFontSize.sm)),
            Text('${_categories[_questions[_currentIndex].category]}',
                style: const TextStyle(
                    color: MiuixColors.primary, fontSize: MiuixFontSize.sm)),
          ],
        ),
        const SizedBox(height: MiuixSpacing.sm),
        MiuixProgress(value: progress),
      ],
    );
  }

  Widget _buildTimerAndScore() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: MiuixSpacing.lg, vertical: MiuixSpacing.sm),
          decoration: BoxDecoration(
            color: _timeLeft <= 5
                ? MiuixColors.error.withValues(alpha: 0.1)
                : MiuixColors.primary.withValues(alpha: 0.1),
            borderRadius: MiuixRadius.pillRadius,
          ),
          child: Row(
            children: [
              Icon(Icons.timer,
                  size: 16,
                  color: _timeLeft <= 5 ? MiuixColors.error : MiuixColors.primary),
              const SizedBox(width: MiuixSpacing.xs),
              Text('$_timeLeft秒',
                  style: TextStyle(
                      color: _timeLeft <= 5
                          ? MiuixColors.error
                          : MiuixColors.primary,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: MiuixSpacing.lg, vertical: MiuixSpacing.sm),
          decoration: BoxDecoration(
            color: MiuixColors.warning.withValues(alpha: 0.1),
            borderRadius: MiuixRadius.pillRadius,
          ),
          child: Row(
            children: [
              const Icon(Icons.star, size: 16, color: MiuixColors.warning),
              const SizedBox(width: MiuixSpacing.xs),
              Text('$_score',
                  style: const TextStyle(
                      color: MiuixColors.warning, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(QuizQuestion q) {
    return MiuixCard(
      child: Text(
        q.question,
        style: const TextStyle(
            fontSize: MiuixFontSize.xl,
            fontWeight: FontWeight.w600,
            color: MiuixColors.textPrimary,
            height: 1.5),
      ),
    );
  }

  Widget _buildAnswerButton(QuizQuestion q, int index) {
    bool isCorrect = index == q.correctIndex;
    bool isSelected = _selectedAnswer == index;
    Color bgColor = MiuixColors.surface;
    Color borderColor = MiuixColors.borderLight;
    Color textColor = MiuixColors.textPrimary;
    IconData? trailingIcon;

    if (_answered) {
      if (isCorrect) {
        bgColor = MiuixColors.success.withValues(alpha: 0.1);
        borderColor = MiuixColors.success;
        textColor = MiuixColors.success;
        trailingIcon = Icons.check_circle;
      } else if (isSelected) {
        bgColor = MiuixColors.error.withValues(alpha: 0.1);
        borderColor = MiuixColors.error;
        textColor = MiuixColors.error;
        trailingIcon = Icons.cancel;
      }
    } else if (isSelected) {
      bgColor = MiuixColors.primary.withValues(alpha: 0.1);
      borderColor = MiuixColors.primary;
      textColor = MiuixColors.primary;
    }

    return GestureDetector(
      onTap: () => _selectAnswer(index),
      child: AnimatedContainer(
        duration: MiuixDuration.fast,
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: MiuixRadius.mdRadius,
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(String.fromCharCode(65 + index),
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: MiuixSpacing.md),
            Expanded(
              child: Text(q.answers[index],
                  style: TextStyle(color: textColor, fontSize: MiuixFontSize.md)),
            ),
            if (trailingIcon != null)
              Icon(trailingIcon, color: textColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildResultPage() {
    final total = _questions.length * 25; // 满分估算
    final percentage = (_score / total * 100).clamp(0, 100).toInt();
    String grade;
    String comment;
    if (percentage >= 90) {
      grade = 'S';
      comment = '太棒了！你是知识达人！';
    } else if (percentage >= 75) {
      grade = 'A';
      comment = '非常优秀！继续保持！';
    } else if (percentage >= 60) {
      grade = 'B';
      comment = '不错哦，还有提升空间！';
    } else {
      grade = 'C';
      comment = '再接再厉，多学习吧！';
    }

    return Column(
      children: [
        _buildAnimatedItem(
          MiuixCard(
            style: MiuixCardStyle.gradient,
            gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
            child: Column(
              children: [
                Text(grade,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: MiuixSpacing.sm),
                Text(comment,
                    style: const TextStyle(color: Colors.white, fontSize: MiuixFontSize.lg)),
                const SizedBox(height: MiuixSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _resultItem('得分', '$_score'),
                    _resultItem('正确率', '$percentage%'),
                    _resultItem('题数', '${_questions.length}'),
                  ],
                ),
              ],
            ),
          ),
          0,
        ),
        const SizedBox(height: MiuixSpacing.xl),
        _buildAnimatedItem(
          MiuixButton(
            label: '再来一局',
            icon: Icons.refresh,
            width: double.infinity,
            onPressed: _startQuiz,
          ),
          1,
        ),
        const SizedBox(height: MiuixSpacing.md),
        _buildAnimatedItem(
          MiuixButton(
            label: '返回菜单',
            icon: Icons.home,
            type: MiuixButtonType.secondary,
            width: double.infinity,
            onPressed: _backToMenu,
          ),
          2,
        ),
      ],
    );
  }

  Widget _resultItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: MiuixFontSize.xxl,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: MiuixFontSize.xs)),
      ],
    );
  }
}

class QuizQuestion {
  final int category;
  final String question;
  final List<String> answers;
  final int correctIndex;

  const QuizQuestion({
    required this.category,
    required this.question,
    required this.answers,
    required this.correctIndex,
  });
}
