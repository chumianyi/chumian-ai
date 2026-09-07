/// ============================================================================
/// Weather —— 天气数据模型
///
/// 承载当前天气、逐小时预报与未来数日预报的完整信息。
/// 包含温度、天气状况、湿度、风力等核心气象指标。
/// ============================================================================

/// 天气状况枚举
enum WeatherCondition {
  /// 晴
  sunny,

  /// 多云
  cloudy,

  /// 阴
  overcast,

  /// 小雨
  lightRain,

  /// 中雨
  moderateRain,

  /// 大雨
  heavyRain,

  /// 雷阵雨
  thunderstorm,

  /// 小雪
  lightSnow,

  /// 中雪
  moderateSnow,

  /// 大雪
  heavySnow,

  /// 雾
  fog,

  /// 霾
  haze,

  /// 未知
  unknown,
}

/// WeatherCondition 枚举的字符串扩展
extension WeatherConditionExtension on WeatherCondition {
  String get value {
    switch (this) {
      case WeatherCondition.sunny:
        return 'sunny';
      case WeatherCondition.cloudy:
        return 'cloudy';
      case WeatherCondition.overcast:
        return 'overcast';
      case WeatherCondition.lightRain:
        return 'light_rain';
      case WeatherCondition.moderateRain:
        return 'moderate_rain';
      case WeatherCondition.heavyRain:
        return 'heavy_rain';
      case WeatherCondition.thunderstorm:
        return 'thunderstorm';
      case WeatherCondition.lightSnow:
        return 'light_snow';
      case WeatherCondition.moderateSnow:
        return 'moderate_snow';
      case WeatherCondition.heavySnow:
        return 'heavy_snow';
      case WeatherCondition.fog:
        return 'fog';
      case WeatherCondition.haze:
        return 'haze';
      case WeatherCondition.unknown:
        return 'unknown';
    }
  }

  /// 中文显示名称
  String get label {
    switch (this) {
      case WeatherCondition.sunny:
        return '晴';
      case WeatherCondition.cloudy:
        return '多云';
      case WeatherCondition.overcast:
        return '阴';
      case WeatherCondition.lightRain:
        return '小雨';
      case WeatherCondition.moderateRain:
        return '中雨';
      case WeatherCondition.heavyRain:
        return '大雨';
      case WeatherCondition.thunderstorm:
        return '雷阵雨';
      case WeatherCondition.lightSnow:
        return '小雪';
      case WeatherCondition.moderateSnow:
        return '中雪';
      case WeatherCondition.heavySnow:
        return '大雪';
      case WeatherCondition.fog:
        return '雾';
      case WeatherCondition.haze:
        return '霾';
      case WeatherCondition.unknown:
        return '未知';
    }
  }

  static WeatherCondition fromString(String? condition) {
    switch (condition) {
      case 'sunny':
      case '晴':
        return WeatherCondition.sunny;
      case 'cloudy':
      case '多云':
        return WeatherCondition.cloudy;
      case 'overcast':
      case '阴':
        return WeatherCondition.overcast;
      case 'light_rain':
      case '小雨':
        return WeatherCondition.lightRain;
      case 'moderate_rain':
      case '中雨':
        return WeatherCondition.moderateRain;
      case 'heavy_rain':
      case '大雨':
        return WeatherCondition.heavyRain;
      case 'thunderstorm':
      case '雷阵雨':
        return WeatherCondition.thunderstorm;
      case 'light_snow':
      case '小雪':
        return WeatherCondition.lightSnow;
      case 'moderate_snow':
      case '中雪':
        return WeatherCondition.moderateSnow;
      case 'heavy_snow':
      case '大雪':
        return WeatherCondition.heavySnow;
      case 'fog':
      case '雾':
        return WeatherCondition.fog;
      case 'haze':
      case '霾':
        return WeatherCondition.haze;
      default:
        return WeatherCondition.unknown;
    }
  }

  /// 是否为雨天
  bool get isRainy =>
      this == WeatherCondition.lightRain ||
      this == WeatherCondition.moderateRain ||
      this == WeatherCondition.heavyRain ||
      this == WeatherCondition.thunderstorm;

  /// 是否为雪天
  bool get isSnowy =>
      this == WeatherCondition.lightSnow ||
      this == WeatherCondition.moderateSnow ||
      this == WeatherCondition.heavySnow;
}

/// 逐小时天气预报
class HourlyWeather {
  /// 时间（小时，0-23）
  final int hour;

  /// 温度（摄氏度）
  final double temperature;

  /// 天气状况
  final WeatherCondition condition;

  /// 降水概率（0-100）
  final int precipitationProbability;

  HourlyWeather({
    required this.hour,
    required this.temperature,
    this.condition = WeatherCondition.unknown,
    this.precipitationProbability = 0,
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    return HourlyWeather(
      hour: (json['hour'] as num?)?.toInt() ?? 0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      condition:
          WeatherConditionExtension.fromString(json['condition']?.toString()),
      precipitationProbability:
          (json['precipitation_probability'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'temperature': temperature,
      'condition': condition.value,
      'precipitation_probability': precipitationProbability,
    };
  }
}

/// 未来数日天气预报
class DailyWeather {
  /// 日期
  final DateTime date;

  /// 最高温度
  final double highTemperature;

  /// 最低温度
  final double lowTemperature;

  /// 白天天气状况
  final WeatherCondition dayCondition;

  /// 夜间天气状况
  final WeatherCondition nightCondition;

  DailyWeather({
    required this.date,
    required this.highTemperature,
    required this.lowTemperature,
    this.dayCondition = WeatherCondition.unknown,
    this.nightCondition = WeatherCondition.unknown,
  });

  factory DailyWeather.fromJson(Map<String, dynamic> json) {
    return DailyWeather(
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      highTemperature: (json['high_temperature'] as num?)?.toDouble() ?? 0.0,
      lowTemperature: (json['low_temperature'] as num?)?.toDouble() ?? 0.0,
      dayCondition: WeatherConditionExtension.fromString(
          json['day_condition']?.toString()),
      nightCondition: WeatherConditionExtension.fromString(
          json['night_condition']?.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'high_temperature': highTemperature,
      'low_temperature': lowTemperature,
      'day_condition': dayCondition.value,
      'night_condition': nightCondition.value,
    };
  }

  /// 日期显示文本，如 "9月6日 周日"
  String get dateLabel {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${date.month}月${date.day}日 ${weekdays[date.weekday - 1]}';
  }
}

/// 天气数据模型
class Weather {
  /// 城市名称
  final String city;

  /// 当前温度（摄氏度）
  final double temperature;

  /// 体感温度
  final double feelsLike;

  /// 天气状况
  final WeatherCondition condition;

  /// 湿度（百分比，0-100）
  final int humidity;

  /// 风速（km/h）
  final double windSpeed;

  /// 风向
  final String windDirection;

  /// 风力等级
  final String windLevel;

  /// 逐小时预报
  final List<HourlyWeather> hourly;

  /// 未来数日预报
  final List<DailyWeather> daily;

  /// 数据更新时间
  final DateTime updatedAt;

  /// 空气质量指数（可选）
  final int? aqi;

  /// 紫外线指数（可选）
  final int? uvIndex;

  /// 能见度（km，可选）
  final double? visibility;

  Weather({
    required this.city,
    required this.temperature,
    this.feelsLike = 0.0,
    this.condition = WeatherCondition.unknown,
    this.humidity = 0,
    this.windSpeed = 0.0,
    this.windDirection = '',
    this.windLevel = '',
    List<HourlyWeather>? hourly,
    List<DailyWeather>? daily,
    DateTime? updatedAt,
    this.aqi,
    this.uvIndex,
    this.visibility,
  })  : hourly = hourly ?? [],
        daily = daily ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  /// 从 JSON 反序列化
  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      city: json['city']?.toString() ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (json['feels_like'] as num?)?.toDouble() ?? 0.0,
      condition:
          WeatherConditionExtension.fromString(json['condition']?.toString()),
      humidity: (json['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: (json['wind_speed'] as num?)?.toDouble() ?? 0.0,
      windDirection: json['wind_direction']?.toString() ?? '',
      windLevel: json['wind_level']?.toString() ?? '',
      hourly: (json['hourly'] as List<dynamic>?)
              ?.map((e) =>
                  HourlyWeather.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      daily: (json['daily'] as List<dynamic>?)
              ?.map((e) =>
                  DailyWeather.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      aqi: (json['aqi'] as num?)?.toInt(),
      uvIndex: (json['uv_index'] as num?)?.toInt(),
      visibility: (json['visibility'] as num?)?.toDouble(),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'temperature': temperature,
      'feels_like': feelsLike,
      'condition': condition.value,
      'humidity': humidity,
      'wind_speed': windSpeed,
      'wind_direction': windDirection,
      'wind_level': windLevel,
      'hourly': hourly.map((e) => e.toJson()).toList(),
      'daily': daily.map((e) => e.toJson()).toList(),
      'updated_at': updatedAt.toIso8601String(),
      'aqi': aqi,
      'uv_index': uvIndex,
      'visibility': visibility,
    };
  }

  /// 温度显示文本，如 "25°"
  String get temperatureText => '${temperature.round()}°';

  /// 湿度显示文本
  String get humidityText => '$humidity%';

  /// 风力显示文本
  String get windText => '$windDirection $windLevel';

  /// 空气质量等级文本
  String get aqiLabel {
    if (aqi == null) return '暂无数据';
    if (aqi! <= 50) return '优';
    if (aqi! <= 100) return '良';
    if (aqi! <= 150) return '轻度污染';
    if (aqi! <= 200) return '中度污染';
    if (aqi! <= 300) return '重度污染';
    return '严重污染';
  }
}
