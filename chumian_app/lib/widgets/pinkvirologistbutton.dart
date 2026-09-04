import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

/// Pink themed virologist button
class PinkVirologistButton extends StatefulWidget {
  final String? text;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double? height;
  final double? radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool enabled;
  final bool loading;
  final bool selected;
  final bool expanded;
  final Widget? leading;
  final Widget? trailing;
  final Widget? child;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final Border? border;
  final AlignmentGeometry? alignment;
  final BoxFit? fit;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final Duration? animationDuration;
  final Curve? animationCurve;
  final bool animate;
  final String? heroTag;
  final String? semanticLabel;
  final String? tooltip;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<bool>? onHover;
  final MouseCursor? mouseCursor;
  final bool enableFeedback;
  final bool excludeFromSemantics;
  final bool isThreeLine;
  final bool dense;
  final bool? enable;
  final VisualDensity? visualDensity;
  final ShapeBorder? cardShape;
  final double? cardElevation;
  final Color? cardColor;
  final Color? cardShadowColor;
  final EdgeInsetsGeometry? cardMargin;
  final Clip? cardClipBehavior;
  final bool? cardBorderOnForeground;
  final bool? cardSemanticContainer;
  final Widget? cardChild;
  final Key? key2;

  const PinkVirologistButton({
    super.key,
    this.text,
    this.subtitle,
    this.icon,
    this.onTap,
    this.onLongPress,
    this.color,
    this.textColor,
    this.width,
    this.height,
    this.radius,
    this.padding,
    this.margin,
    this.enabled = true,
    this.loading = false,
    this.selected = false,
    this.expanded = false,
    this.leading,
    this.trailing,
    this.child,
    this.boxShadow,
    this.gradient,
    this.border,
    this.alignment,
    this.fit,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.animationDuration,
    this.animationCurve,
    this.animate = true,
    this.heroTag,
    this.semanticLabel,
    this.tooltip,
    this.autofocus = false,
    this.focusNode,
    this.onFocusChange,
    this.onHover,
    this.mouseCursor,
    this.enableFeedback = true,
    this.excludeFromSemantics = false,
    this.isThreeLine = false,
    this.dense = false,
    this.enable,
    this.visualDensity,
    this.cardShape,
    this.cardElevation,
    this.cardColor,
    this.cardShadowColor,
    this.cardMargin,
    this.cardClipBehavior,
    this.cardBorderOnForeground,
    this.cardSemanticContainer,
    this.cardChild,
    this.key2,
  });

  @override
  State<PinkVirologistButton> createState() => _PinkVirologistButtonState();
}

class _PinkVirologistButtonState extends State<PinkVirologistButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration ?? const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: widget.animationCurve ?? Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: widget.animationCurve ?? Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.loading) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled || widget.loading) return;
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleLongPress() {
    if (!widget.enabled || widget.loading) return;
    widget.onLongPress?.call();
  }

  void _handleHover(bool hovered) {
    setState(() => _isHovered = hovered);
    widget.onHover?.call(hovered);
  }

  void _handleFocusChange(bool focused) {
    setState(() => _isFocused = focused);
    widget.onFocusChange?.call(focused);
  }

  Color get _effectiveColor => widget.color ?? AppColors.primary;
  Color get _effectiveTextColor => widget.textColor ?? AppColors.textOnPrimary;
  double get _effectiveRadius => widget.radius ?? AppRadius.md;

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    final result = widget.heroTag != null
        ? Hero(tag: widget.heroTag!, child: content)
        : content;
    return widget.tooltip != null
        ? Tooltip(message: widget.tooltip!, child: result)
        : result;
  }

  Widget _buildContent() {
    return Semantics(
      label: widget.semanticLabel ?? widget.text,
      enabled: widget.enabled,
      checked: widget.selected,
      button: true,
      excludeSemantics: widget.excludeFromSemantics,
      child: Focus(
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        onFocusChange: _handleFocusChange,
        child: MouseRegion(
          cursor: widget.mouseCursor ?? (widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic),
          onHover: (_) => _handleHover(true),
          onExit: (_) => _handleHover(false),
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onLongPress: _handleLongPress,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: child,
                  ),
                );
              },
              child: _buildVisual(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisual() {
    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      padding: widget.padding ?? AppSpacing.buttonPadding,
      alignment: widget.alignment,
      decoration: BoxDecoration(
        color: widget.gradient == null ? (_isHovered ? _effectiveColor.withValues(alpha: 0.9) : _effectiveColor) : null,
        gradient: widget.gradient ?? (widget.selected ? AppColors.primaryVibrantGradient : AppColors.primaryGradient),
        borderRadius: BorderRadius.circular(_effectiveRadius),
        border: widget.border ?? (_isFocused ? Border.all(color: AppColors.accent, width: 2) : null),
        boxShadow: widget.boxShadow ?? (_isHovered ? AppShadows.pinkLg : AppShadows.pinkMd),
      ),
      clipBehavior: widget.clipBehavior ?? Clip.antiAlias,
      child: widget.child ?? _buildDefaultChild(),
    );
  }

  Widget _buildDefaultChild() {
    if (widget.loading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_effectiveTextColor),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leading != null) widget.leading!,
        if (widget.leading != null || widget.icon != null) const SizedBox(width: AppSpacing.sm),
        if (widget.icon != null) Icon(widget.icon, color: _effectiveTextColor, size: 20),
        if (widget.icon != null && widget.text != null) const SizedBox(width: AppSpacing.sm),
        if (widget.text != null) Flexible(
          child: Text(
            widget.text!,
            style: AppTextStyles.button.copyWith(color: _effectiveTextColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(widget.subtitle!, style: AppTextStyles.caption.copyWith(color: _effectiveTextColor.withValues(alpha: 0.8))),
        ],
        if (widget.trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          widget.trailing!,
        ],
      ],
    );
  }
}
