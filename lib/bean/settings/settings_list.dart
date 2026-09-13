import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/widget/content_section.dart';
import 'package:kazumi/bean/widget/split_list_row.dart';
import 'package:kazumi/services/platform/tv_mode.dart';

enum _TileKind { plain, toggle, radio }

class SettingsList extends StatelessWidget {
  const SettingsList({
    super.key,
    required this.sections,
    this.maxWidth = 1000,
  });

  final List<Widget> sections;

  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: sections.length,
      itemBuilder: (context, index) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: sections[index],
        ),
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.tiles,
    this.title,
    this.bottomInfo,
    this.margin,
  });

  final List<Widget> tiles;
  final Widget? title;
  final Widget? bottomInfo;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SectionHeader(title: title!),
            ),
          SplitListGroup(children: tiles),
          if (bottomInfo != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: DefaultTextStyle.merge(
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
                child: bottomInfo!,
              ),
            ),
        ],
      ),
    );
  }
}

class SettingsRadioSection<T> extends StatelessWidget {
  const SettingsRadioSection({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.tiles,
    this.title,
  });

  final T? groupValue;
  final ValueChanged<T?> onChanged;
  final List<Widget> tiles;
  final Widget? title;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<T>(
      groupValue: groupValue,
      onChanged: onChanged,
      child: SettingsSection(title: title, tiles: tiles),
    );
  }
}

Color _disabledOn(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);

class _TileLabel extends StatelessWidget {
  const _TileLabel({
    required this.title,
    this.leading,
    this.description,
    this.enabled = true,
  });

  final Widget title;
  final IconData? leading;
  final Widget? description;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final disabled = enabled ? null : _disabledOn(context);
    final foreground = disabled ?? colorScheme.onSurface;
    final secondary = disabled ?? colorScheme.onSurfaceVariant;

    return Row(
      children: [
        if (leading != null) ...[
          Icon(leading, size: 24, color: secondary),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultTextStyle.merge(
                style: textTheme.bodyLarge?.copyWith(color: foreground),
                child: title,
              ),
              if (description != null) ...[
                const SizedBox(height: 2),
                DefaultTextStyle.merge(
                  style: textTheme.bodySmall?.copyWith(color: secondary),
                  child: description!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsCategoryTile extends StatelessWidget {
  const SettingsCategoryTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      onHighlightChanged: SplitListRow.pressReporterOf(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.bodyLarge),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsSliderTile extends StatefulWidget {
  const SettingsSliderTile({
    super.key,
    required this.title,
    required this.value,
    required this.valueLabel,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.leading,
    this.description,
  });

  final Widget title;
  final IconData? leading;
  final Widget? description;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  State<SettingsSliderTile> createState() => _SettingsSliderTileState();
}

class _SettingsSliderTileState extends State<SettingsSliderTile> {
  // On TV the row itself takes focus; the Slider is not focusable so it can
  // never swallow arrow keys. Left/right on the row adjust the value, and
  // up/down are left for normal focus traversal.
  final FocusNode _rowFocusNode =
      FocusNode(debugLabel: 'SettingsSliderTile row');
  final FocusNode _sliderFocusNode =
      FocusNode(canRequestFocus: false, skipTraversal: true);
  bool _rowFocused = false;

  @override
  void dispose() {
    _rowFocusNode.dispose();
    _sliderFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleRowKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final divisions = widget.divisions;
    final step = divisions != null && divisions > 0
        ? (widget.max - widget.min) / divisions
        : (widget.max - widget.min) / 20;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      widget.onChanged((widget.value + step).clamp(widget.min, widget.max));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      widget.onChanged((widget.value - step).clamp(widget.min, widget.max));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _TileLabel(
                  title: widget.title,
                  leading: widget.leading,
                  description: widget.description,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.valueLabel,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            focusNode: TvMode.enabled ? _sliderFocusNode : null,
            value: widget.value,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            showValueIndicator: ShowValueIndicator.never,
            padding: EdgeInsets.zero,
            onChanged: widget.onChanged,
          ),
        ],
      ),
    );

    if (!TvMode.enabled) {
      return content;
    }
    return Focus(
      focusNode: _rowFocusNode,
      onKeyEvent: _handleRowKey,
      onFocusChange: (focused) => setState(() => _rowFocused = focused),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _rowFocused
                ? colorScheme.primary
                : colorScheme.primary.withValues(alpha: 0),
            width: 2,
          ),
        ),
        child: content,
      ),
    );
  }
}

class SettingsTile<T> extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    this.leading,
    this.description,
    this.trailing,
    this.value,
    this.onPressed,
    this.enabled = true,
  })  : _kind = _TileKind.plain,
        onToggle = null,
        initialValue = null,
        radioValue = null;

  /// Row taps pass null to [onToggle]; switch gestures pass the new value.
  const SettingsTile.switchTile({
    super.key,
    required this.title,
    required this.initialValue,
    required this.onToggle,
    this.leading,
    this.description,
    this.enabled = true,
  })  : _kind = _TileKind.toggle,
        trailing = null,
        value = null,
        onPressed = null,
        radioValue = null;

  const SettingsTile.radioTile({
    super.key,
    required this.title,
    required T this.radioValue,
    this.leading,
    this.description,
    this.enabled = true,
  })  : _kind = _TileKind.radio,
        trailing = null,
        value = null,
        onPressed = null,
        onToggle = null,
        initialValue = null;

  final Widget title;

  final IconData? leading;
  final Widget? description;
  final Widget? trailing;
  final Widget? value;
  final void Function(BuildContext context)? onPressed;
  final void Function(bool? value)? onToggle;
  final bool? initialValue;
  final T? radioValue;
  final bool enabled;
  final _TileKind _kind;

  VoidCallback? _tapHandler(BuildContext context) {
    if (!enabled) {
      return null;
    }
    switch (_kind) {
      case _TileKind.plain:
        return onPressed == null ? null : () => onPressed!(context);
      case _TileKind.toggle:
        return onToggle == null ? null : () => onToggle!(null);
      case _TileKind.radio:
        final registry = RadioGroup.maybeOf<T>(context);
        return registry == null ? null : () => registry.onChanged(radioValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final secondary =
        enabled ? colorScheme.onSurfaceVariant : _disabledOn(context);

    final row = InkWell(
      canRequestFocus: !TvMode.enabled,
      onTap: _tapHandler(context),
      onHighlightChanged: SplitListRow.pressReporterOf(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32),
          child: Row(
            children: [
              Expanded(
                child: _TileLabel(
                  title: title,
                  leading: leading,
                  description: description,
                  enabled: enabled,
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 12),
                DefaultTextStyle.merge(
                  style: textTheme.bodyMedium?.copyWith(color: secondary),
                  child: value!,
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: 8),
                IconTheme.merge(
                  data: IconThemeData(color: secondary),
                  child: trailing!,
                ),
              ],
              if (_kind == _TileKind.toggle) ...[
                const SizedBox(width: 12),
                Switch(
                  value: initialValue ?? false,
                  onChanged: enabled ? onToggle : null,
                ),
              ],
              if (_kind == _TileKind.radio) ...[
                const SizedBox(width: 12),
                Radio<T>(value: radioValue as T, enabled: enabled),
              ],
            ],
          ),
        ),
      ),
    );

    if (!TvMode.enabled) {
      return row;
    }
    // On TV the theme focus overlay alone is nearly invisible; give every
    // settings row the same clear focus frame as the slider rows. The outer
    // Focus node is the sole traversal target and forwards OK to the row's
    // tap handler (the inner InkWell is not focusable here).
    return _TvRowFocusHighlight(
      onActivate: _tapHandler(context),
      child: row,
    );
  }
}

/// TV 行级焦点视觉：主题色实线边框 + 轻微填充。遥控器上下移动时清晰可辨。
class _TvRowFocusHighlight extends StatefulWidget {
  const _TvRowFocusHighlight({required this.child, this.onActivate});

  final Widget child;
  final VoidCallback? onActivate;

  @override
  State<_TvRowFocusHighlight> createState() => _TvRowFocusHighlightState();
}

class _TvRowFocusHighlightState extends State<_TvRowFocusHighlight> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'SettingsRow');
  bool _focused = false;

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    final isActivateKey = event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA;
    if (!isActivateKey) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    widget.onActivate?.call();
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          border: Border.all(
            color: _focused
                ? colorScheme.primary
                : colorScheme.primary.withValues(alpha: 0),
            width: 2.5,
          ),
          color: _focused
              ? colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: widget.child,
      ),
    );
  }
}

/// TV 端"多选一"行：行内显示当前值，按 OK 弹出选项对话框，选中即应用。
/// 非电视端不使用（radio 页保持原样）。
class TvSelectionTile<T> extends StatelessWidget {
  const TvSelectionTile({
    super.key,
    required this.title,
    required this.items,
    required this.groupValue,
    required this.onChanged,
    this.leading,
  });

  final Widget title;
  final IconData? leading;
  final Map<T, String> items;
  final T groupValue;
  final ValueChanged<T> onChanged;

  void _openSelectionDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    KazumiDialog.show(
      builder: (context) {
        return AlertDialog(
          title: title,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in items.entries)
                    InkWell(
                      onTap: () {
                        KazumiDialog.dismiss();
                        if (entry.key != groupValue) {
                          onChanged(entry.key);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.value,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            if (entry.key == groupValue)
                              Icon(Icons.check_rounded,
                                  size: 22, color: colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLabel = items[groupValue] ?? groupValue.toString();
    return SettingsTile<String>(
      title: title,
      leading: leading,
      value: Text(currentLabel),
      onPressed: (_) => _openSelectionDialog(context),
    );
  }
}
