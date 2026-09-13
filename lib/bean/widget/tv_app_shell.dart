import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/bean/widget/tv_back_interceptor.dart';
import 'package:kazumi/bean/widget/tv_focus_navigation.dart';
import 'package:kazumi/navigation.dart';
import 'package:kazumi/services/platform/tv_mode.dart';
import 'package:kazumi/services/platform/tv_navigation.dart';

/// Applies TV-only focus behavior while preserving the normal mobile theme.
class TvAppShell extends StatefulWidget {
  const TvAppShell({super.key, required this.child});

  final Widget child;

  @override
  State<TvAppShell> createState() => _TvAppShellState();
}

class _TvAppShellState extends State<TvAppShell>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('com.predidit.kazumi/tv_navigation');

  double _lastViewInsetBottom = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (TvMode.enabled) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'home') TvNavigation.goHome();
        if (call.method == 'back') {
          if (TvBackInterceptor.handle()) return;
          await rootNavigatorKey.currentState?.maybePop();
        }
      });
      _channel.invokeMethod<void>('setActive', true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (TvMode.enabled) {
      _channel.setMethodCallHandler(null);
      _channel.invokeMethod<void>('setActive', false);
    }
    super.dispose();
  }

  // After the on-screen keyboard closes, the TextField often keeps primary
  // focus, so arrow keys only move the caret and directional focus is stuck.
  // Release text focus whenever the IME hides while an editable field owns
  // focus; focus returns to the traversal scope the dialog came from.
  @override
  void didChangeMetrics() {
    if (!TvMode.enabled || !mounted) return;
    final insetBottom =
        MediaQueryData.fromView(View.of(context)).viewInsets.bottom;
    final wasVisible = _lastViewInsetBottom > 0;
    _lastViewInsetBottom = insetBottom;
    if (!wasVisible || insetBottom > 0) return;
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || focus.context == null) return;
    final ctx = focus.context!;
    final isEditable = ctx.widget is EditableText ||
        ctx.findAncestorStateOfType<EditableTextState>() != null;
    if (isEditable) {
      focus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!TvMode.enabled) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Theme(
      data: theme.copyWith(
        focusColor: colorScheme.primary.withValues(alpha: 0.45),
        hoverColor: colorScheme.primary.withValues(alpha: 0.22),
        visualDensity: VisualDensity.comfortable,
      ),
      child: FocusTraversalGroup(
        policy: TvLoopTraversalPolicy(),
        child: widget.child,
      ),
    );
  }
}
