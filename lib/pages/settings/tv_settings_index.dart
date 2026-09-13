import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:kazumi/bean/widget/tv_focusable_surface.dart';
import 'package:kazumi/pages/settings/settings_page.dart';

/// TV 端"我的"页 = 简化设置索引：纯文字行，无图形卡片。
/// 条目按 OK 推根导航器全屏路由（遥控器返回键退出），不走 outlet。
class TvSettingsIndexPage extends StatelessWidget {
  const TvSettingsIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rows = <Widget>[];
    for (final group in settingsGroups) {
      rows.add(Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
        child: Text(
          group.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ));
      for (final category in group.categories) {
        rows.add(_TvSettingsEntryRow(category: category));
      }
    }

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: Text(
                '设置',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _TvSettingsEntryRow extends StatelessWidget {
  const _TvSettingsEntryRow({required this.category});

  final SettingsCategory category;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TvFocusableSurface(
        borderRadius: 14,
        focusScale: 1,
        onPressed: () => context.pushNamed(category.path),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  category.label,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  category.description,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: colors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
