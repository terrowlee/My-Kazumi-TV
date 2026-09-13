import 'package:kazumi/utils/async_serial_queue.dart';

typedef PlaybackProgressWriter = Future<void> Function(
    Duration position, Duration duration);

/// One recorder per native media session. Inputs must come from native state,
/// never from a requested seek target or a prepared route.
class PlaybackHistoryRecorder {
  PlaybackHistoryRecorder(this._write);

  final PlaybackProgressWriter _write;
  final AsyncSerialQueue _writes = AsyncSerialQueue();
  bool _hasPlayed = false;
  (Duration, Duration)? _saved;
  DateTime? _lastWriteAt;

  // Each write serializes the whole History object into Hive and appends a
  // sync-change record; per-second writes trigger frequent Hive compactions
  // that freeze the entire UI for seconds on TV flash storage. Progress only
  // needs second-level granularity for resume, so throttle to 5s while
  // playing. Pauses, seeks and the final save always write immediately.
  static const _minWriteInterval = Duration(seconds: 5);
  static const _seekJumpThreshold = Duration(seconds: 5);

  void observePlaying(bool playing) {
    _hasPlayed |= playing;
  }

  Future<void> record({
    required Duration position,
    required Duration duration,
    required bool playing,
  }) {
    observePlaying(playing);
    if (!_hasPlayed ||
        duration <= Duration.zero ||
        position < Duration.zero ||
        position > duration) {
      return Future<void>.value();
    }
    final snapshot = (position, duration);
    return _writes.run(() async {
      if (_saved == snapshot) return;
      final elapsed = _lastWriteAt == null
          ? null
          : DateTime.now().difference(_lastWriteAt!);
      final seeked = _saved != null &&
          (position - _saved!.$1).abs() > _seekJumpThreshold;
      final shouldWrite =
          !playing || elapsed == null || elapsed >= _minWriteInterval || seeked;
      if (!shouldWrite) return;
      await _write(position, duration);
      _saved = snapshot;
      _lastWriteAt = DateTime.now();
    });
  }
}
