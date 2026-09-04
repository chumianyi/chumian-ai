import 'package:flutter/material.dart';

/// 全局圆角规范
class AppRadius {
  AppRadius._();
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 22;
  static const double xxl = 28;
  static const double xxxl = 36;
  static const double huge = 48;
  static const double pill = 999;

  static const BorderRadius allXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius allSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius allMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius allXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius allXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius allXxxl = BorderRadius.all(Radius.circular(xxxl));
  static const BorderRadius allHuge = BorderRadius.all(Radius.circular(huge));
  static const BorderRadius allPill = BorderRadius.all(Radius.circular(pill));

  static const BorderRadius topXs = BorderRadius.vertical(top: Radius.circular(xs));
  static const BorderRadius topSm = BorderRadius.vertical(top: Radius.circular(sm));
  static const BorderRadius topMd = BorderRadius.vertical(top: Radius.circular(md));
  static const BorderRadius topLg = BorderRadius.vertical(top: Radius.circular(lg));
  static const BorderRadius topXl = BorderRadius.vertical(top: Radius.circular(xl));
  static const BorderRadius topXxl = BorderRadius.vertical(top: Radius.circular(xxl));
  static const BorderRadius topPill = BorderRadius.vertical(top: Radius.circular(pill));

  static const BorderRadius bottomXs = BorderRadius.vertical(bottom: Radius.circular(xs));
  static const BorderRadius bottomSm = BorderRadius.vertical(bottom: Radius.circular(sm));
  static const BorderRadius bottomMd = BorderRadius.vertical(bottom: Radius.circular(md));
  static const BorderRadius bottomLg = BorderRadius.vertical(bottom: Radius.circular(lg));
  static const BorderRadius bottomXl = BorderRadius.vertical(bottom: Radius.circular(xl));
  static const BorderRadius bottomXxl = BorderRadius.vertical(bottom: Radius.circular(xxl));
  static const BorderRadius bottomPill = BorderRadius.vertical(bottom: Radius.circular(pill));

  static const Radius radiusXs = Radius.circular(xs);
  static const Radius radiusSm = Radius.circular(sm);
  static const Radius radiusMd = Radius.circular(md);
  static const Radius radiusLg = Radius.circular(lg);
  static const Radius radiusXl = Radius.circular(xl);
  static const Radius radiusXxl = Radius.circular(xxl);
  static const Radius radiusPill = Radius.circular(pill);

  static BorderRadius only({
    double? topLeft,
    double? topRight,
    double? bottomLeft,
    double? bottomRight,
  }) =>
      BorderRadius.only(
        topLeft: Radius.circular(topLeft ?? 0),
        topRight: Radius.circular(topRight ?? 0),
        bottomLeft: Radius.circular(bottomLeft ?? 0),
        bottomRight: Radius.circular(bottomRight ?? 0),
      );

  static BorderRadius horizontal(double radius) => BorderRadius.horizontal(
        left: Radius.circular(radius),
        right: Radius.circular(radius),
      );

  static BorderRadius vertical(double radius) => BorderRadius.vertical(
        top: Radius.circular(radius),
        bottom: Radius.circular(radius),
      );
}
