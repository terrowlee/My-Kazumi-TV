import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/utils/constants.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:kazumi/services/platform/tv_mode.dart';

class RendererSettings extends StatefulWidget {
  const RendererSettings({super.key});

  @override
  State<RendererSettings> createState() => _RendererSettingsState();
}

class _RendererSettingsState extends State<RendererSettings> {
  late String _renderer =
      GStorage.getSetting(SettingsKeys.androidVideoRenderer);
  late bool _surfaceProducer =
      GStorage.getSetting(SettingsKeys.androidSurfaceProducer);

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: const Text('视频渲染器'),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text('选择合适的渲染器以获得最佳播放体验'),
            tiles: [
              TvSelectionTile<String>(
                title: const Text('视频渲染器'),
                items: {
                  for (final e in androidVideoRenderersList.entries)
                    e.key: (TvMode.enabled && e.key == 'auto')
                        ? 'auto（电视推荐）'
                        : e.key,
                },
                groupValue: _renderer,
                onChanged: (String? value) {
                  if (value != null) {
                    GStorage.putSetting<String>(
                        SettingsKeys.androidVideoRenderer, value);
                    setState(() {
                      _renderer = value;
                    });
                  }
                },
              ),
              if (Platform.isAndroid)
                SettingsTile.switchTile(
                  title: const Text('SurfaceProducer 合成管线'),
                  description: const Text(
                    '实验：使用 Flutter 新的 ImageReader/HardwareBuffer 视频合成路径，'
                    '可显著降低高分辨率视频的每帧合成开销、改善播放界面流畅度。'
                    '下次播放生效；若出现黑屏或异常请关闭。',
                  ),
                  initialValue: _surfaceProducer,
                  onToggle: (value) async {
                    final newValue = value ?? !_surfaceProducer;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.androidSurfaceProducer, newValue);
                    setState(() {
                      _surfaceProducer = newValue;
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
