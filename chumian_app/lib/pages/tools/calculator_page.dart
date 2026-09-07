import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// CalculatorPage —— 计算器
/// 粉色主题计算器，按键水晕，动画，历史记录，科学计算模式
/// ============================================================
class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  String _display = '0';
  String _expression = '';
  double _firstNum = 0;
  String _operator = '';
  bool _waitingForSecond = false;
  bool _isScientific = false;
  List<String> _history = [];

  static const List<String> _buttons = [
    'C', '±', '%', '÷',
    '7', '8', '9', '×',
    '4', '5', '6', '-',
    '1', '2', '3', '+',
    '⌫', '0', '.', '=',
  ];

  static const List<String> _sciButtons = [
    'sin', 'cos', 'tan', 'log',
    '√', 'x²', 'xʸ', 'π',
    'C', '±', '%', '÷',
    '7', '8', '9', '×',
    '4', '5', '6', '-',
    '1', '2', '3', '+',
    '⌫', '0', '.', '=',
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
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.03, (index * 0.03) + 0.3,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) => Opacity(opacity: anim.value, child: child),
    );
  }

  void _onButtonPressed(String button) {
    HapticFeedback.lightImpact();
    setState(() {
      if (button == 'C') {
        _clear();
      } else if (button == '⌫') {
        _backspace();
      } else if (button == '±') {
        _toggleSign();
      } else if (button == '%') {
        _percent();
      } else if (button == '=') {
        _calculate();
      } else if (_isOperator(button)) {
        _setOperator(button);
      } else if (button == '.') {
        _addDecimal();
      } else if (_isScientificFunction(button)) {
        _applyScientific(button);
      } else {
        _addDigit(button);
      }
    });
  }

  bool _isOperator(String button) =>
      button == '+' || button == '-' || button == '×' || button == '÷' || button == 'xʸ';

  bool _isScientificFunction(String button) =>
      button == 'sin' ||
      button == 'cos' ||
      button == 'tan' ||
      button == 'log' ||
      button == '√' ||
      button == 'x²' ||
      button == 'π';

  void _clear() {
    _display = '0';
    _expression = '';
    _firstNum = 0;
    _operator = '';
    _waitingForSecond = false;
  }

  void _backspace() {
    if (_display.length > 1) {
      _display = _display.substring(0, _display.length - 1);
    } else {
      _display = '0';
    }
  }

  void _toggleSign() {
    if (_display != '0') {
      _display = _display.startsWith('-')
          ? _display.substring(1)
          : '-$_display';
    }
  }

  void _percent() {
    final value = double.parse(_display) / 100;
    _display = _formatResult(value);
  }

  void _setOperator(String op) {
    if (_operator.isNotEmpty && !_waitingForSecond) {
      _calculate();
    }
    _firstNum = double.parse(_display);
    _operator = op;
    _expression = '$_display $op';
    _waitingForSecond = true;
  }

  void _addDigit(String digit) {
    if (_waitingForSecond) {
      _display = digit;
      _waitingForSecond = false;
    } else {
      if (_display == '0') {
        _display = digit;
      } else {
        if (_display.replaceAll('-', '').replaceAll('.', '').length < 12) {
          _display += digit;
        }
      }
    }
  }

  void _addDecimal() {
    if (_waitingForSecond) {
      _display = '0.';
      _waitingForSecond = false;
    } else if (!_display.contains('.')) {
      _display += '.';
    }
  }

  void _calculate() {
    if (_operator.isEmpty) return;
    final secondNum = double.parse(_display);
    double result = 0;
    switch (_operator) {
      case '+':
        result = _firstNum + secondNum;
        break;
      case '-':
        result = _firstNum - secondNum;
        break;
      case '×':
        result = _firstNum * secondNum;
        break;
      case '÷':
        result = secondNum != 0 ? _firstNum / secondNum : 0;
        break;
      case 'xʸ':
        result = _pow(_firstNum, secondNum.toInt());
        break;
    }
    final expr = '$_expression $_display =';
    _history.insert(0, '$expr  ${_formatResult(result)}');
    if (_history.length > 20) _history.removeLast();
    _display = _formatResult(result);
    _expression = '';
    _operator = '';
    _waitingForSecond = true;
  }

  double _pow(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp.abs(); i++) {
      result *= base;
    }
    return exp < 0 ? 1 / result : result;
  }

  void _applyScientific(String func) {
    final value = double.parse(_display);
    double result = 0;
    switch (func) {
      case 'sin':
        result = _sin(value);
        break;
      case 'cos':
        result = _cos(value);
        break;
      case 'tan':
        result = _tan(value);
        break;
      case 'log':
        result = value > 0 ? _log10(value) : 0;
        break;
      case '√':
        result = value >= 0 ? _sqrt(value) : 0;
        break;
      case 'x²':
        result = value * value;
        break;
      case 'π':
        _display = '3.14159265359';
        return;
    }
    _history.insert(0, '$func($value) = ${_formatResult(result)}');
    if (_history.length > 20) _history.removeLast();
    _display = _formatResult(result);
    _waitingForSecond = true;
  }

  double _sin(double x) => _approxSin(x * 3.14159265359 / 180);
  double _cos(double x) => _approxCos(x * 3.14159265359 / 180);
  double _tan(double x) {
    final c = _approxCos(x * 3.14159265359 / 180);
    return c.abs() > 0.0001
        ? _approxSin(x * 3.14159265359 / 180) / c
        : 0;
  }

  double _approxSin(double x) {
    x = x % (2 * 3.14159265359);
    double result = 0;
    double term = x;
    for (int n = 1; n <= 10; n++) {
      result += term;
      term *= -x * x / ((2 * n) * (2 * n + 1));
    }
    return result;
  }

  double _approxCos(double x) {
    x = x % (2 * 3.14159265359);
    double result = 1;
    double term = 1;
    for (int n = 1; n <= 10; n++) {
      term *= -x * x / ((2 * n - 1) * (2 * n));
      result += term;
    }
    return result;
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _log10(double x) {
    if (x <= 0) return 0;
    double result = 0;
    while (x >= 10) {
      x /= 10;
      result++;
    }
    while (x < 1) {
      x *= 10;
      result--;
    }
    double ln = 0;
    double y = (x - 1) / (x + 1);
    double term = y;
    for (int i = 1; i <= 20; i += 2) {
      ln += term / i;
      term *= y * y;
    }
    return result + 2 * ln / 2.302585093;
  }

  String _formatResult(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final buttons = _isScientific ? _sciButtons : _buttons;
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '计算器',
        backgroundColor: MiuixColors.background,
        actions: [
          MiuixIconButton(
            icon: _isScientific ? Icons.calculate : Icons.science,
            style: MiuixIconButtonStyle.ghost,
            onPressed: () => setState(() => _isScientific = !_isScientific),
          ),
          MiuixIconButton(
            icon: Icons.history,
            style: MiuixIconButtonStyle.ghost,
            onPressed: _showHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDisplay(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: _isScientific ? 1.2 : 1.1,
              ),
              itemCount: buttons.length,
              itemBuilder: (context, index) {
                return _buildAnimatedItem(
                  _buildCalcButton(buttons[index]),
                  index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplay() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)],
        ),
        borderRadius: MiuixRadius.xlRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _expression,
            style: const TextStyle(
              fontSize: MiuixFontSize.md,
              color: MiuixColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              _display,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: MiuixColors.primaryDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcButton(String label) {
    final isOperator = _isOperator(label) || label == '=';
    final isFunction = label == 'C' ||
        label == '±' ||
        label == '%' ||
        label == '⌫' ||
        _isScientificFunction(label);

    return MiuixRipple(
      borderRadius: MiuixRadius.lg,
      child: GestureDetector(
        onTap: () => _onButtonPressed(label),
        child: AnimatedContainer(
          duration: MiuixDuration.instant,
          curve: MiuixCurves.miuixSpring,
          decoration: BoxDecoration(
            gradient: isOperator
                ? const LinearGradient(colors: MiuixColors.primaryGradient)
                : null,
            color: isOperator
                ? null
                : isFunction
                    ? MiuixColors.primaryLight.withOpacity(0.2)
                    : MiuixColors.surface,
            borderRadius: MiuixRadius.lgRadius,
            boxShadow: isOperator ? MiuixShadows.sm : MiuixShadows.xs,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: _isScientific && label.length > 1 ? 14 : 22,
                fontWeight: FontWeight.w600,
                color: isOperator
                    ? Colors.white
                    : isFunction
                        ? MiuixColors.primary
                        : MiuixColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: MiuixColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(MiuixRadius.xl)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MiuixColors.border,
                borderRadius: MiuixRadius.pillRadius,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '计算历史',
              style: TextStyle(
                fontSize: MiuixFontSize.xl,
                fontWeight: FontWeight.bold,
                color: MiuixColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _history.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      '暂无计算记录',
                      style: TextStyle(color: MiuixColors.textTertiary),
                    ),
                  )
                : SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            _history[index],
                            style: const TextStyle(
                              fontSize: MiuixFontSize.md,
                              color: MiuixColors.textPrimary,
                            ),
                          ),
                          onTap: () {
                            final result = _history[index].split('=').last.trim();
                            setState(() => _display = result);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class HapticFeedback {
  static void lightImpact() {}
}
