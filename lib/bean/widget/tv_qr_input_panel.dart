import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:kazumi/services/platform/tv_mode.dart';
import 'package:kazumi/services/tv/qr_input_service.dart';

/// 二维码输入面板：绑定 [targetId] 到局域网输入服务，手机扫码后输入的文字
/// 通过 [onText] 回传。服务不可用时整个面板不显示。
class TvQrInputPanel extends StatefulWidget {
  const TvQrInputPanel({
    super.key,
    required this.targetId,
    required this.onText,
    this.size = 120,
    this.hint = '手机扫码\n直接输入',
  });

  final String targetId;
  final ValueChanged<String> onText;
  final double size;
  final String hint;

  @override
  State<TvQrInputPanel> createState() => _TvQrInputPanelState();
}

class _TvQrInputPanelState extends State<TvQrInputPanel> {
  String? _url;

  @override
  void initState() {
    super.initState();
    if (!TvMode.enabled) return;
    TvQrInputService.instance
        .bindTarget(widget.targetId, widget.onText)
        .then((url) {
      if (!mounted || url == null) return;
      setState(() => _url = url);
    });
  }

  @override
  void dispose() {
    TvQrInputService.instance.unbindTarget(widget.targetId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_url == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: QrImageView(
            data: _url!,
            size: widget.size,
            gapless: true,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.hint,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
