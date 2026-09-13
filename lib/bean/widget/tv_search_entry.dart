import 'package:flutter/material.dart';
import 'package:kazumi/bean/widget/tv_focusable_surface.dart';
import 'package:kazumi/bean/widget/tv_qr_input_panel.dart';
import 'package:kazumi/services/tv/qr_input_service.dart';

/// Remote focus is an action, not an editable field. Text editing starts only
/// after explicit activation, in its own route so BACK restores this entry.
class TvSearchEntry extends StatefulWidget {
  const TvSearchEntry({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.suggestionsBuilder,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final WidgetBuilder? suggestionsBuilder;

  @override
  State<TvSearchEntry> createState() => _TvSearchEntryState();
}

class _TvSearchEntryState extends State<TvSearchEntry> {
  final _focus = FocusNode(debugLabel: 'TV search input entry');
  bool _opening = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_opening) return;
    _opening = true;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _SearchEditor(
        initialText: widget.controller.text,
        suggestionsBuilder: widget.suggestionsBuilder,
      ),
    );
    _opening = false;
    if (!mounted) return;
    _focus.requestFocus();
    if (result != null) widget.onSubmitted(result);
  }

  @override
  Widget build(BuildContext context) => TvFocusableSurface(
        key: const Key('tv-search-entry'),
        focusNode: _focus,
        autofocus: true,
        borderRadius: 28,
        focusScale: 1,
        onPressed: _open,
        child: SearchBar(
          controller: widget.controller,
          readOnly: true,
          hintText: '按 OK 输入名称或搜索条件',
          leading: const Icon(Icons.search),
          onTap: _open,
          elevation: const WidgetStatePropertyAll(0),
        ),
      );
}

class _SearchEditor extends StatefulWidget {
  const _SearchEditor({required this.initialText, this.suggestionsBuilder});
  final String initialText;
  final WidgetBuilder? suggestionsBuilder;

  @override
  State<_SearchEditor> createState() => _SearchEditorState();
}

class _SearchEditorState extends State<_SearchEditor> {
  late final editor = TextEditingController(text: widget.initialText);
  bool _remoteReceived = false;

  void _applyRemoteText(String text) {
    if (!mounted) return;
    // Ignore a second phone submission after the dialog already popped.
    if (_remoteReceived) return;
    _remoteReceived = true;
    editor.text = text;
    Navigator.of(context).pop(text);
  }

  @override
  void dispose() {
    TvQrInputService.instance.unbindTarget('search');
    editor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('搜索番剧'),
        scrollable: true,
        content: SizedBox(
          width: 560,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  key: const Key('tv-search-editor'),
                  controller: editor,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) => Navigator.of(context).pop(value),
                  decoration: const InputDecoration(hintText: '输入名称或搜索条件'),
                ),
                if (widget.suggestionsBuilder != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 140),
                    child: SingleChildScrollView(
                      child: widget.suggestionsBuilder!(context),
                    ),
                  ),
              ]),
            ),
            const SizedBox(width: 20),
            TvQrInputPanel(
              targetId: 'search',
              onText: _applyRemoteText,
              size: 116,
              hint: '手机扫码\n直接打字搜索',
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(editor.text),
            child: const Text('检索'),
          ),
        ],
      );
}
