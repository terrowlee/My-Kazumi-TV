import 'package:flutter/services.dart';
import 'package:kazumi/services/platform/tv_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:kazumi/bean/widget/content_section.dart';
import 'package:kazumi/bean/widget/tv_back_interceptor.dart';
import 'package:kazumi/navigation.dart';
import 'package:kazumi/pages/settings/player_settings.dart';
import 'package:kazumi/utils/constants.dart';

class SettingsCategory {
  const SettingsCategory({
    required this.label,
    required this.description,
    required this.icon,
    required this.path,
  });

  final String label;
  final String description;
  final IconData icon;
  final String path;
}

class SettingsGroup {
  const SettingsGroup({required this.title, required this.categories});

  final String title;
  final List<SettingsCategory> categories;
}

const List<SettingsGroup> settingsGroups = [
  SettingsGroup(
    title: '播放',
    categories: [
      SettingsCategory(
        label: '播放设置',
        description: '解码、渲染与播放行为',
        icon: Icons.display_settings_rounded,
        path: '/settings/player',
      ),
      SettingsCategory(
        label: '弹幕设置',
        description: '弹幕来源与显示效果',
        icon: Icons.subtitles_rounded,
        path: '/settings/danmaku',
      ),
      SettingsCategory(
        label: '操作设置',
        description: '播放器按键映射',
        icon: Icons.keyboard_rounded,
        path: '/settings/keyboard',
      ),
    ],
  ),
  SettingsGroup(
    title: '资源',
    categories: [
      SettingsCategory(
        label: '规则管理',
        description: '番剧资源规则',
        icon: Icons.extension_rounded,
        path: '/settings/plugin',
      ),
      SettingsCategory(
        label: '下载设置',
        description: '并发数与弹幕缓存',
        icon: Icons.downloading_rounded,
        path: '/settings/download-settings',
      ),
    ],
  ),
  SettingsGroup(
    title: '应用',
    categories: [
      SettingsCategory(
        label: '外观设置',
        description: '主题、配色与字体',
        icon: Icons.palette_rounded,
        path: '/settings/theme',
      ),
      SettingsCategory(
        label: '界面设置',
        description: '启动、窗口行为与展示信息',
        icon: Icons.pages_rounded,
        path: '/settings/interface',
      ),
      SettingsCategory(
        label: '同步设置',
        description: '追番状态与多设备同步',
        icon: Icons.cloud_rounded,
        path: '/settings/sync',
      ),
      SettingsCategory(
        label: '网络设置',
        description: '访问加速与代理',
        icon: Icons.language_rounded,
        path: '/settings/proxy',
      ),
    ],
  ),
  SettingsGroup(
    title: '其他',
    categories: [
      SettingsCategory(
        label: '更新设置',
        description: '应用与规则更新',
        icon: Icons.update_rounded,
        path: '/settings/update',
      ),
      SettingsCategory(
        label: '存储与日志',
        description: '图片缓存与错误日志',
        icon: Icons.storage_rounded,
        path: '/settings/storage',
      ),
      SettingsCategory(
        label: '关于',
        description: '版本与开源信息',
        icon: Icons.info_outline_rounded,
        path: '/settings/about',
      ),
    ],
  ),
];

String _normalizePath(String path) =>
    path.endsWith('/') ? path.substring(0, path.length - 1) : path;

bool _isWithinPath(String location, String path) =>
    location == path || location.startsWith('$path/');

String _categoryPath(String location) {
  if (location == '/settings') {
    return '/settings/player';
  }
  if (_isWithinPath(location, '/settings/bangumi') ||
      _isWithinPath(location, '/settings/webdav')) {
    return '/settings/sync';
  }
  for (final group in settingsGroups) {
    for (final category in group.categories) {
      if (_isWithinPath(location, category.path)) {
        return category.path;
      }
    }
  }
  return location;
}

class SettingsCategorySelected extends Notification {
  const SettingsCategorySelected(this.path);

  final String path;
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.location});

  final String location;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _paneFocus = FocusScopeNode(debugLabel: 'TV settings pane');
  final _railNodes = <String, FocusNode>{};

  FocusNode _railNode(String path) => _railNodes.putIfAbsent(
      path, () => FocusNode(debugLabel: 'TV settings category $path'));

  @override
  void initState() {
    super.initState();
    if (TvMode.enabled) {
      TvBackInterceptor.register(_handleTvBack);
    }
  }

  @override
  void dispose() {
    if (TvMode.enabled) {
      TvBackInterceptor.unregister(_handleTvBack);
    }
    _paneFocus.dispose();
    for (final node in _railNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  /// TV back key: inside a detail pane, back first moves focus to the
  /// category sidebar (same as LEFT); with the sidebar focused, back exits
  /// settings to the main page.
  bool _handleTvBack() {
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return false;
    final railNode = _railNode(_selectedCategoryPath);
    final focus = FocusManager.instance.primaryFocus;
    if (focus == railNode) {
      // Sidebar already focused: exit settings (inner stack is discarded).
      rootNavigatorKey.currentState?.pop();
      return true;
    }
    if (focus == null || _focusInPane(focus) || _location == '/settings') {
      railNode.requestFocus();
      return true;
    }
    // Focus somewhere unexpected (e.g. inside a dialog-less overlay): let the
    // normal pop flow handle it.
    return false;
  }

  bool _focusInPane(FocusNode focus) {
    for (FocusNode? node = focus; node != null; node = node.parent) {
      if (node == _paneFocus) return true;
    }
    return false;
  }

  void _enterPane() {
    final previous = _paneFocus.focusedChild;
    if (previous != null &&
        previous is! FocusScopeNode &&
        previous.canRequestFocus) {
      previous.requestFocus();
      return;
    }
    for (final node in _paneFocus.traversalDescendants) {
      if (node is! FocusScopeNode && node.canRequestFocus) {
        node.requestFocus();
        return;
      }
    }
  }

  final _outletKey = GlobalKey<RouterOutletState>();
  Object? _categoryNavigation;
  // Nested pushes do not update the root route state.
  late String _location = _normalizePath(widget.location);

  String get _selectedCategoryPath => _categoryPath(_location);
  bool get _isSecondaryRoute =>
      _location != '/settings' && _location != _selectedCategoryPath;

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _categoryNavigation = null;
      _location = _normalizePath(widget.location);
    }
  }

  void _replaceCategory(String path) {
    _categoryNavigation = null;
    _outletKey.currentState!.navigate(path);
    setState(() => _location = _normalizePath(path));
  }

  Future<void> _pushCategory(String path) async {
    if (_categoryNavigation != null) return;
    final navigation = Object();
    final previousLocation = _location;
    _categoryNavigation = navigation;
    setState(() => _location = _normalizePath(path));
    await _outletKey.currentState!.push<void>(path);
    // Ignore completions from history replaced by a rail selection.
    if (!mounted || _categoryNavigation != navigation) return;
    setState(() {
      _categoryNavigation = null;
      _location = previousLocation;
    });
  }

  void _goBack() {
    if (_outletKey.currentState?.maybePop() ?? false) return;
    _exitSettings();
  }

  void _exitSettings() {
    if (!context.maybePop()) context.navigate('/tab/my');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // TV is always wide: the category sidebar + detail pane must never
      // collapse into the standalone list layout.
      final wide = TvMode.enabled ||
          constraints.maxWidth > LayoutBreakpoint.compact['width']!;
      return NavigatorPopHandler<Object?>(
        onPopWithResult: (_) => _goBack(),
        child: Scaffold(
          appBar: wide
              ? SysAppBar(
                  title: const Text('设置'),
                  leading:
                      TvMode.enabled ? null : BackButton(onPressed: _exitSettings),
                )
              : null,
          body: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Keep the outlet at the same tree position on resize.
                SizedBox(
                  width: wide ? 280 : 0,
                  child: Offstage(
                    offstage: !wide,
                    child: _SettingsMenu(
                      wide: true,
                      selectedPath: _selectedCategoryPath,
                      onSelect: _replaceCategory,
                      nodeForPath: TvMode.enabled ? _railNode : null,
                      onEnterPane: _enterPane,
                    ),
                  ),
                ),
                Expanded(
                  child: FocusScope(
                    node: _paneFocus,
                    onKeyEvent: (node, event) {
                      if (TvMode.enabled &&
                          wide &&
                          event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                        _railNode(_selectedCategoryPath).requestFocus();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: SettingsPaneScope(
                      embedded: wide,
                      showBackButton: _isSecondaryRoute,
                      onBack: _goBack,
                      child: NotificationListener<SettingsCategorySelected>(
                        onNotification: (notification) {
                          _pushCategory(notification.path);
                          return true;
                        },
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            pageTransitionsTheme: settingsPageTransitionsTheme,
                          ),
                          child: RouterOutlet(key: _outletKey),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class SettingsIndexPage extends StatelessWidget {
  const SettingsIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (SettingsPaneScope.of(context)?.embedded ?? false) {
      return const PlayerSettingsPage();
    }
    return Scaffold(
      appBar: SysAppBar(
        title: const Text('设置'),
        leading: TvMode.enabled
            ? null
            : BackButton(onPressed: () {
                if (!context.maybePop()) context.navigate('/tab/my');
              }),
      ),
      body: _SettingsMenu(
        wide: false,
        onSelect: (path) => SettingsCategorySelected(path).dispatch(context),
      ),
    );
  }
}

class _SettingsMenu extends StatelessWidget {
  const _SettingsMenu({
    required this.wide,
    this.selectedPath,
    required this.onSelect,
    this.nodeForPath,
    this.onEnterPane,
  });

  final bool wide;
  final String? selectedPath;
  final ValueChanged<String> onSelect;
  final FocusNode Function(String)? nodeForPath;
  final VoidCallback? onEnterPane;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView(
        padding: wide
            ? const EdgeInsets.fromLTRB(4, 0, 0, 12)
            : const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (final group in settingsGroups)
            if (wide) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
                child: SectionHeader(title: Text(group.title)),
              ),
              for (final category in group.categories)
                _RailDestination(
                  category: category,
                  selected: selectedPath == category.path,
                  onTap: () => onSelect(category.path),
                  focusNode: nodeForPath?.call(category.path),
                  onEnterPane: onEnterPane,
                ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ContentSection.group(
                  title: group.title,
                  children: [
                    for (final category in group.categories)
                      SettingsCategoryTile(
                        icon: category.icon,
                        title: category.label,
                        description: category.description,
                        onTap: () => onSelect(category.path),
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _RailDestination extends StatelessWidget {
  const _RailDestination({
    required this.category,
    required this.selected,
    required this.onTap,
    this.focusNode,
    this.onEnterPane,
  });

  final SettingsCategory category;
  final bool selected;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final VoidCallback? onEnterPane;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = selected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? colorScheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: (_, event) {
            if (TvMode.enabled &&
                event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.arrowRight) {
              onEnterPane?.call();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: InkWell(
            focusNode: focusNode,
            onTap: onTap,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(category.icon, size: 24, color: foreground),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.label,
                      style: textTheme.labelLarge?.copyWith(color: foreground),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
