import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../utils/animations.dart';
import '../../../utils/theme_helper.dart';

export '../../../utils/animations.dart';

class AdminColors {
  // Light
  static const background = Color(0xFFF4F9FA);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF102A43);
  static const textSecondary = Color(0xFF52616B);
  // Dark
  static const backgroundDark = Color(0xFF12121C);
  static const surfaceDark = Color(0xFF1E1E2E);
  static const cardDark = Color(0xFF242436);
  static const textPrimaryDark = Color(0xFFEAEEF4);
  static const textSecondaryDark = Color(0xFF8B93A1);
  // Brand (shared)
  static const brand = Color(0xFF0E7C86);
  static const brandDark = Color(0xFF0B5D66);
  static const brandSoft = Color(0xFFE7F6F7);
  static const brandSoftDark = Color(0xFF0E2F33);
  static const accent = Color(0xFF17A2B8);
}

class AdminRadii {
  static const card = 18.0;
  static const button = 12.0;
  static const input = 14.0;
}

class AdminTextStyles {
  static const pageTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AdminColors.textPrimary,
    letterSpacing: -0.4,
  );

  static const sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AdminColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const body = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: AdminColors.textSecondary,
  );

  static const appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AdminColors.textPrimary,
    letterSpacing: -0.3,
  );
}

Widget adminSectionHeader(String title) => _AdminSectionHeader(title: title);

Widget adminListCard({
  required Widget child,
  EdgeInsets padding = const EdgeInsets.all(14),
  EdgeInsets margin = const EdgeInsets.only(bottom: 10),
  BorderRadius borderRadius = const BorderRadius.all(Radius.circular(14)),
  bool animate = false,
  Duration animationDuration = const Duration(milliseconds: 300),
}) {
  if (!animate) {
    return Builder(
      builder: (context) => Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: borderRadius,
          boxShadow: context.cardShadow,
        ),
        child: child,
      ),
    );
  }

  return _AnimatedCardShell(
    margin: margin,
    padding: padding,
    borderRadius: borderRadius,
    child: child,
  );
}

Widget adminStatCard({
  required String label,
  required String value,
  required IconData icon,
  Color iconColor = AdminColors.brand,
  String? trend,
  Color? trendColor,
}) {
  return _AdminStatCard(
    label: label,
    value: value,
    icon: icon,
    iconColor: iconColor,
    trend: trend,
    trendColor: trendColor,
  );
}

Widget adminPill(String label, Color color, {Color? textColor}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: textColor ?? color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

Widget adminPrimaryButton({
  required VoidCallback? onPressed,
  required Widget child,
  bool isLoading = false,
}) {
  return _AdminPrimaryButton(
    onPressed: onPressed,
    isLoading: isLoading,
    child: child,
  );
}

Widget adminDangerButton({
  required VoidCallback? onPressed,
  required Widget child,
}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red.shade50,
      foregroundColor: Colors.red,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminRadii.button),
      ),
      elevation: 0,
    ),
    child: DefaultTextStyle.merge(
      style: const TextStyle(fontWeight: FontWeight.w700),
      child: child,
    ),
  );
}

Widget adminSearchField({
  TextEditingController? controller,
  String? hintText,
  ValueChanged<String>? onChanged,
  Widget? prefixIcon,
}) {
  return Builder(
    builder: (context) => TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText ?? 'Search...',
        prefixIcon:
            prefixIcon ??
            Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminRadii.input),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminRadii.input),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AdminRadii.input)),
          borderSide: BorderSide(color: AdminColors.brand, width: 1.3),
        ),
      ),
    ),
  );
}

Widget adminQuickActionCard({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
  Color? borderColor,
}) {
  return _AdminQuickActionCard(
    icon: icon,
    title: title,
    subtitle: subtitle,
    onTap: onTap,
    borderColor: borderColor ?? AdminColors.brand,
  );
}

Widget adminSettingsRow({
  required IconData icon,
  required String title,
  required String subtitle,
  required Widget trailing,
}) {
  return _AnimatedSettingsRow(
    icon: icon,
    title: title,
    subtitle: subtitle,
    trailing: trailing,
  );
}

/// Hero header widget for admin pages
Widget adminHeroHeader({
  required String title,
  required String subtitle,
  List<Widget>? actions,
}) {
  return _AdminHeroHeader(title: title, subtitle: subtitle, actions: actions);
}

class _AdminSectionHeader extends StatefulWidget {
  final String title;

  const _AdminSectionHeader({required this.title});

  @override
  State<_AdminSectionHeader> createState() => _AdminSectionHeaderState();
}

class _AdminSectionHeaderState extends State<_AdminSectionHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 350),
    vsync: this,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    return FadeTransition(
      opacity: animation,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Row(
          children: [
            Text(
              widget.title,
              style: AdminTextStyles.sectionTitle.copyWith(color: context.textPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AdminColors.brand,
                      AdminColors.brand.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCardShell extends StatefulWidget {
  final EdgeInsets margin;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final Widget child;

  const _AnimatedCardShell({
    required this.margin,
    required this.padding,
    required this.borderRadius,
    required this.child,
  });

  @override
  State<_AnimatedCardShell> createState() => _AnimatedCardShellState();
}

class _AnimatedCardShellState extends State<_AnimatedCardShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.14),
          end: Offset.zero,
        ).animate(animation),
        child: Container(
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: widget.borderRadius,
            boxShadow: context.cardShadow,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _AdminStatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? trend;
  final Color? trendColor;

  const _AdminStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.trend,
    this.trendColor,
  });

  @override
  State<_AdminStatCard> createState() => _AdminStatCardState();
}

class _AdminStatCardState extends State<_AdminStatCard> {
  @override
  Widget build(BuildContext context) {
    final target = int.tryParse(widget.value) ?? 0;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: PressableWidget(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AdminRadii.card),
            boxShadow: context.cardShadow,
          ),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(AdminRadii.card),
                  border: Border(
                    left: BorderSide(color: widget.iconColor, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AdminColors.brand, AdminColors.accent],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(height: 14),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: target.toDouble()),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.label,
                      style: AdminTextStyles.body.copyWith(
                        fontSize: 13,
                        color: context.textSecondary,
                      ),
                    ),
                    if (widget.trend != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (widget.trendColor ?? Colors.green).withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          widget.trend!,
                          style: TextStyle(
                            color: widget.trendColor ?? Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminQuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color borderColor;

  const _AdminQuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: PressableWidget(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: borderColor, width: 4)),
            boxShadow: context.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      borderColor.withValues(alpha: 0.2),
                      borderColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: borderColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedSettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _AnimatedSettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: context.cardShadow,
      ),
      child: Row(
        children: [
          Icon(icon, color: context.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _AdminPrimaryButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;

  const _AdminPrimaryButton({
    required this.onPressed,
    required this.child,
    required this.isLoading,
  });

  @override
  State<_AdminPrimaryButton> createState() => _AdminPrimaryButtonState();
}

class _AdminPrimaryButtonState extends State<_AdminPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: widget.isLoading
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            },
      onTapCancel: widget.isLoading
          ? null
          : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.bounceOut,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AdminColors.brand, AdminColors.accent],
            ),
            borderRadius: BorderRadius.circular(AdminRadii.button),
            boxShadow: [
              BoxShadow(
                color: AdminColors.brand.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(AdminRadii.button),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  child: Center(
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminHeroHeader extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Widget>? actions;

  const _AdminHeroHeader({
    required this.title,
    required this.subtitle,
    this.actions,
  });

  @override
  State<_AdminHeroHeader> createState() => _AdminHeroHeaderState();
}

class _AdminHeroHeaderState extends State<_AdminHeroHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 400),
    vsync: this,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.08),
          end: Offset.zero,
        ).animate(animation),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AdminColors.brand, AdminColors.brandDark],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.actions != null) ...[
                    const SizedBox(width: 16),
                    ...widget.actions!,
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminPageWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  // Default true — back button shown whenever the navigator can pop.
  // Pass showBackButton: false on root admin screens (Dashboard, Users, etc.)
  // that should never show a back arrow.
  final bool showBackButton;

  const AdminPageWrapper({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showBackButton = true,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  void _handleBack(BuildContext context) {
    context.go(AppRoutes.adminHome);
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = showBackButton;

    final scaffold = Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        surfaceTintColor: context.surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: context.textPrimary,
          letterSpacing: -0.3,
        ),
        title: Text(title),
        leading: canGoBack
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: context.textPrimary),
                onPressed: () => _handleBack(context),
              )
            : null,
        actions: actions,
      ),
      body: child,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );

    return SafeArea(
      child: canGoBack
          ? PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) return;
                _handleBack(context);
              },
              child: scaffold,
            )
          : scaffold,
    );
  }
}
