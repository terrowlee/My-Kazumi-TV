import 'package:flutter/material.dart';
import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/utils/constants.dart';
import 'package:kazumi/bean/settings/settings_list.dart';

class DecoderSettings extends StatefulWidget {
  const DecoderSettings({super.key});

  @override
  State<DecoderSettings> createState() => _DecoderSettingsState();
}

class _DecoderSettingsState extends State<DecoderSettings> {
  late String _decoder = GStorage.getSetting(SettingsKeys.hardwareDecoder);

  void _update(String? value) {
    if (value != null) {
      GStorage.putSetting<String>(SettingsKeys.hardwareDecoder, value);
      setState(() {
        _decoder = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: const Text('硬件解码器'),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text('选择不受支持的解码器将回退到软件解码'),
            tiles: [
              TvSelectionTile<String>(
                title: const Text('硬件解码器'),
                items: hardwareDecodersList,
                groupValue: _decoder,
                onChanged: _update,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
