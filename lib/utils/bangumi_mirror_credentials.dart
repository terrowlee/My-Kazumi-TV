// Bangumi mirror API credentials for the search signature flow.
// Release/PR CI injects them via --dart-define=KAZUMI_APPID / KAZUMI_KEY.
const Map<String, String> bangumiMirrorCredentials = {
  'id': String.fromEnvironment('KAZUMI_APPID'),
  'value': String.fromEnvironment('KAZUMI_KEY'),
};

/// Open-source/local builds have no mirror credentials; requests must stay on
/// the official api.bgm.tv host (unsigned) instead of the signature-protected
/// mirror, otherwise search and comments fail with 403.
bool get hasBangumiMirrorCredentials =>
    (bangumiMirrorCredentials['id'] ?? '').trim().isNotEmpty &&
    (bangumiMirrorCredentials['value'] ?? '').trim().isNotEmpty;
