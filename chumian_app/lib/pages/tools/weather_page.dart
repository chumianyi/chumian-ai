import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// WeatherPage —— 天气页
/// 城市选择，当前天气(粉色渐变背景)，逐时预报，7日预报
/// 天气动画图标(自定义绘制)
/// ============================================================
class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _weatherController;

  String _city = '六安';
  bool _isLoading = false;

  static const List<String> _cities = ['六安', '合肥', '上海', '北京', '深圳', '杭州', '成都', '武汉'];

  final WeatherData _currentWeather = WeatherData(
    temp: 26,
    condition: '多云',
    icon: Icons.wb_cloudy,
    humidity: 65,
    wind: '东南风 3级',
    feelsLike: 28,
    uv: '中等',
    pressure: 1013,
  );

  final List<HourlyWeather> _hourly = [
    HourlyWeather(time: '现在', temp: 26, icon: Icons.wb_cloudy),
    HourlyWeather(time: '14时', temp: 27, icon: Icons.wb_sunny),
    HourlyWeather(time: '15时', temp: 28, icon: Icons.wb_sunny),
    HourlyWeather(time: '16时', temp: 27, icon: Icons.wb_cloudy),
    HourlyWeather(time: '17时', temp: 25, icon: Icons.wb_cloudy),
    HourlyWeather(time: '18时', temp: 23, icon: Icons.nights_stay),
    HourlyWeather(time: '19时', temp: 22, icon: Icons.nights_stay),
    HourlyWeather(time: '20时', temp: 21, icon: Icons.nights_stay),
  ];

  final List<DailyWeather> _daily = [
    DailyWeather(day: '今天', high: 29, low: 21, icon: Icons.wb_cloudy, condition: '多云'),
    DailyWeather(day: '周一', high: 30, low: 22, icon: Icons.wb_sunny, condition: '晴'),
    DailyWeather(day: '周二', high: 28, low: 20, icon: Icons.grain, condition: '小雨'),
    DailyWeather(day: '周三', high: 25, low: 18, icon: Icons.beach_access, condition: '中雨'),
    DailyWeather(day: '周四', high: 27, low: 19, icon: Icons.wb_cloudy, condition: '阴'),
    DailyWeather(day: '周五', high: 29, low: 21, icon: Icons.wb_sunny, condition: '晴'),
    DailyWeather(day: '周六', high: 31, low: 23, icon: Icons.wb_sunny, condition: '晴'),
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _weatherController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _weatherController.dispose();
    super.dispose();
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

  void _selectCity() {
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
              '选择城市',
              style: TextStyle(
                fontSize: MiuixFontSize.xl,
                fontWeight: FontWeight.bold,
                color: MiuixColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_cities.length, (index) {
                final isSelected = _city == _cities[index];
                return MiuixRipple(
                  borderRadius: MiuixRadius.pill,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _city = _cities[index]);
                      Navigator.pop(context);
                      MiuixToast.show(context,
                          message: '已切换到 $_city',
                          type: MiuixToastType.success);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: MiuixColors.primaryGradient)
                            : null,
                        color: isSelected ? null : MiuixColors.surfaceVariant,
                        borderRadius: MiuixRadius.pillRadius,
                      ),
                      child: Text(
                        _cities[index],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : MiuixColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCurrentWeather(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildAnimatedItem(_buildHourlyForecast(), 0),
                  const SizedBox(height: 16),
                  _buildAnimatedItem(_buildDailyForecast(), 1),
                  const SizedBox(height: 16),
                  _buildAnimatedItem(_buildWeatherDetails(), 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeather() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFB6C1), Color(0xFFFF8FB5), Color(0xFFFF6B9D)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(MiuixRadius.xxl),
          bottomRight: Radius.circular(MiuixRadius.xxl),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MiuixIconButton(
                icon: Icons.arrow_back,
                style: MiuixIconButtonStyle.glass,
                onPressed: () => Navigator.pop(context),
              ),
              MiuixRipple(
                borderRadius: MiuixRadius.pill,
                child: GestureDetector(
                  onTap: _selectCity,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: MiuixRadius.pillRadius,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _city,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down,
                            color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 动画天气图标
          AnimatedBuilder(
            animation: _weatherController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(100, 100),
                painter: _WeatherIconPainter(_weatherController.value),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_currentWeather.temp}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.w200,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  '°C',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ],
          ),
          Text(
            _currentWeather.condition,
            style: const TextStyle(
              color: Colors.white,
              fontSize: MiuixFontSize.xl,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '体感温度 ${_currentWeather.feelsLike}°C',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: MiuixFontSize.sm,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '逐时预报',
            style: TextStyle(
              fontSize: MiuixFontSize.md,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _hourly.length,
              itemBuilder: (context, index) {
                final hour = _hourly[index];
                return Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: index == 0
                        ? MiuixColors.primaryLight.withOpacity(0.15)
                        : MiuixColors.surfaceVariant,
                    borderRadius: MiuixRadius.mdRadius,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        hour.time,
                        style: TextStyle(
                          fontSize: MiuixFontSize.xs,
                          color: index == 0
                              ? MiuixColors.primary
                              : MiuixColors.textTertiary,
                          fontWeight: index == 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      Icon(hour.icon,
                          color: MiuixColors.primary, size: 22),
                      Text(
                        '${hour.temp}°',
                        style: const TextStyle(
                          fontSize: MiuixFontSize.md,
                          fontWeight: FontWeight.w600,
                          color: MiuixColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyForecast() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '7日预报',
            style: TextStyle(
              fontSize: MiuixFontSize.md,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_daily.length, (index) {
            final day = _daily[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      day.day,
                      style: TextStyle(
                        fontSize: MiuixFontSize.sm,
                        color: index == 0
                            ? MiuixColors.primary
                            : MiuixColors.textSecondary,
                        fontWeight: index == 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Icon(day.icon, color: MiuixColors.primary, size: 20),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: Text(
                      day.condition,
                      style: const TextStyle(
                        fontSize: MiuixFontSize.xs,
                        color: MiuixColors.textTertiary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${day.low}°',
                          style: const TextStyle(
                            fontSize: MiuixFontSize.sm,
                            color: MiuixColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: ClipRRect(
                            borderRadius: MiuixRadius.pillRadius,
                            child: LinearProgressIndicator(
                              value: (day.high - 15) / 20,
                              minHeight: 4,
                              backgroundColor: MiuixColors.surfaceVariant,
                              valueColor: const AlwaysStoppedAnimation(
                                  MiuixColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${day.high}°',
                          style: const TextStyle(
                            fontSize: MiuixFontSize.sm,
                            fontWeight: FontWeight.w600,
                            color: MiuixColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeatherDetails() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2,
      children: [
        _buildDetailCard(Icons.water_drop, '湿度', '${_currentWeather.humidity}%'),
        _buildDetailCard(Icons.air, '风力', _currentWeather.wind),
        _buildDetailCard(Icons.wb_sunny, '紫外线', _currentWeather.uv),
        _buildDetailCard(Icons.speed, '气压', '${_currentWeather.pressure}hPa'),
      ],
    );
  }

  Widget _buildDetailCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MiuixColors.surface,
        borderRadius: MiuixRadius.mdRadius,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MiuixColors.primaryLight.withOpacity(0.15),
              borderRadius: MiuixRadius.smRadius,
            ),
            child: Icon(icon, color: MiuixColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: MiuixFontSize.xs,
                  color: MiuixColors.textTertiary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WeatherData {
  final int temp;
  final String condition;
  final IconData icon;
  final int humidity;
  final String wind;
  final int feelsLike;
  final String uv;
  final int pressure;
  const WeatherData({
    required this.temp,
    required this.condition,
    required this.icon,
    required this.humidity,
    required this.wind,
    required this.feelsLike,
    required this.uv,
    required this.pressure,
  });
}

class HourlyWeather {
  final String time;
  final int temp;
  final IconData icon;
  const HourlyWeather(
      {required this.time, required this.temp, required this.icon});
}

class DailyWeather {
  final String day;
  final int high;
  final int low;
  final IconData icon;
  final String condition;
  const DailyWeather({
    required this.day,
    required this.high,
    required this.low,
    required this.icon,
    required this.condition,
  });
}

/// 天气动画图标绘制器
class _WeatherIconPainter extends CustomPainter {
  final double progress;
  _WeatherIconPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 太阳光芒
    final sunPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi + progress * 0.5;
      final innerR = 28.0;
      final outerR = 36.0 + math.sin(progress * 2 * math.pi + i) * 3;
      canvas.drawLine(
        Offset(center.dx + math.cos(angle) * innerR,
            center.dy + math.sin(angle) * innerR),
        Offset(center.dx + math.cos(angle) * outerR,
            center.dy + math.sin(angle) * outerR),
        sunPaint,
      );
    }

    // 太阳
    canvas.drawCircle(
      center,
      22,
      Paint()..color = Colors.white.withOpacity(0.9),
    );

    // 云朵
    final cloudPaint = Paint()..color = Colors.white;
    final cloudOffset = Offset(8 + math.sin(progress * 2 * math.pi) * 3, 10);
    canvas.drawCircle(
      center + cloudOffset,
      16,
      cloudPaint,
    );
    canvas.drawCircle(
      center + cloudOffset + const Offset(14, 2),
      12,
      cloudPaint,
    );
    canvas.drawCircle(
      center + cloudOffset + const Offset(-12, 4),
      10,
      cloudPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + cloudOffset + const Offset(2, 8),
        width: 36,
        height: 16,
      ),
      cloudPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
