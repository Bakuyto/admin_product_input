import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

enum CustomButtonVariant {
  filled,
  outlined,
  text,
  icon,
}

enum CustomButtonSize {
  small,
  medium,
  large,
}

class CustomButton extends StatefulWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final CustomButtonVariant variant;
  final CustomButtonSize size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const CustomButton({
    Key? key,
    this.text,
    this.icon,
    this.onPressed,
    this.variant = CustomButtonVariant.filled,
    this.size = CustomButtonSize.medium,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  // Convenience constructors
  const CustomButton.filled({
    Key? key,
    required String text,
    required VoidCallback onPressed,
    CustomButtonSize size = CustomButtonSize.medium,
    Color? backgroundColor,
    Color? foregroundColor,
    bool isLoading = false,
    bool isDisabled = false,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
  }) : this(
          key: key,
          text: text,
          onPressed: onPressed,
          variant: CustomButtonVariant.filled,
          size: size,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          isLoading: isLoading,
          isDisabled: isDisabled,
          width: width,
          height: height,
          padding: padding,
          borderRadius: borderRadius,
        );

  const CustomButton.outlined({
    Key? key,
    required String text,
    required VoidCallback onPressed,
    CustomButtonSize size = CustomButtonSize.medium,
    Color? foregroundColor,
    bool isLoading = false,
    bool isDisabled = false,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
  }) : this(
          key: key,
          text: text,
          onPressed: onPressed,
          variant: CustomButtonVariant.outlined,
          size: size,
          foregroundColor: foregroundColor,
          isLoading: isLoading,
          isDisabled: isDisabled,
          width: width,
          height: height,
          padding: padding,
          borderRadius: borderRadius,
        );

  const CustomButton.icon({
    Key? key,
    required IconData icon,
    required VoidCallback onPressed,
    String? text,
    CustomButtonSize size = CustomButtonSize.medium,
    Color? backgroundColor,
    Color? foregroundColor,
    bool isLoading = false,
    bool isDisabled = false,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
  }) : this(
          key: key,
          text: text,
          icon: icon,
          onPressed: onPressed,
          variant: CustomButtonVariant.icon,
          size: size,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          isLoading: isLoading,
          isDisabled: isDisabled,
          width: width,
          height: height,
          padding: padding,
          borderRadius: borderRadius,
        );

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: ThemeConstants.animationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      _scaleController.reverse();
    }
  }

  void _handleTapCancel() {
    if (!widget.isDisabled && !widget.isLoading) {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine colors based on variant using static ThemeConstants
    Color bgColor;
    Color fgColor;
    Color? borderColor;
    double elevation;

    switch (widget.variant) {
      case CustomButtonVariant.filled:
        bgColor = widget.backgroundColor ?? ThemeConstants.primaryColor;
        fgColor = widget.foregroundColor ?? Colors.white;
        elevation = 2;
        break;
      case CustomButtonVariant.outlined:
        bgColor = Colors.transparent;
        fgColor = widget.foregroundColor ?? ThemeConstants.primaryColor;
        borderColor = fgColor;
        elevation = 0;
        break;
      case CustomButtonVariant.text:
        bgColor = Colors.transparent;
        fgColor = widget.foregroundColor ?? ThemeConstants.primaryColor;
        elevation = 0;
        break;
      case CustomButtonVariant.icon:
        bgColor = widget.backgroundColor ?? ThemeConstants.surfaceColor;
        fgColor = widget.foregroundColor ?? ThemeConstants.textPrimary;
        elevation = 1;
        break;
    }

    // Adjust for disabled state
    if (widget.isDisabled || widget.isLoading) {
      bgColor = bgColor.withOpacity(0.5);
      fgColor = fgColor.withOpacity(0.5);
      borderColor = borderColor?.withOpacity(0.5);
      elevation = 0;
    }

    // Determine size
    double fontSize;
    double iconSize;
    EdgeInsetsGeometry buttonPadding;
    double? buttonHeight;

    switch (widget.size) {
      case CustomButtonSize.small:
        fontSize = 12;
        iconSize = 16;
        buttonPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
        buttonHeight = 32;
        break;
      case CustomButtonSize.medium:
        fontSize = 14;
        iconSize = 20;
        buttonPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
        buttonHeight = 40;
        break;
      case CustomButtonSize.large:
        fontSize = 16;
        iconSize = 24;
        buttonPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
        buttonHeight = 48;
        break;
    }

    // Override with custom values
    buttonPadding = widget.padding ?? buttonPadding;
    buttonHeight = widget.height ?? buttonHeight;

    // Build button content
    Widget content;
    if (widget.isLoading) {
      content = SizedBox(
        width: iconSize,
        height: iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(fgColor),
        ),
      );
    } else {
      final children = <Widget>[];

      if (widget.icon != null) {
        children.add(Icon(
          widget.icon,
          size: iconSize,
          color: fgColor,
        ));

        if (widget.text != null) {
          children.add(SizedBox(width: ThemeConstants.spacingS));
        }
      }

      if (widget.text != null) {
        children.add(Text(
          widget.text!,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: fgColor,
          ),
        ));
      }

      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      );
    }

    // Build button shape
    final shape = RoundedRectangleBorder(
      borderRadius: widget.borderRadius ??
          BorderRadius.circular(ThemeConstants.radiusM),
      side: borderColor != null
          ? BorderSide(color: borderColor, width: 1.5)
          : BorderSide.none,
    );

    // Build the button
    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            color: bgColor,
            elevation: elevation,
            shadowColor: ThemeConstants.primaryColor.withOpacity(0.3),
            shape: shape,
            child: InkWell(
              onTap: widget.isDisabled || widget.isLoading ? null : widget.onPressed,
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              borderRadius: widget.borderRadius ??
                  BorderRadius.circular(ThemeConstants.radiusM),
              child: Container(
                width: widget.width,
                height: buttonHeight,
                padding: buttonPadding,
                alignment: Alignment.center,
                child: content,
              ),
            ),
          ),
        );
      },
    );

    return Semantics(
      button: true,
      enabled: !widget.isDisabled && !widget.isLoading,
      label: widget.text ?? 'Button',
      child: button,
    );
  }
}
