/// A piece of media to play on a casting-capable device: a URL the device
/// itself fetches (the phone doesn't stream it).
class TvMediaItem {
  const TvMediaItem({
    required this.url,
    required this.contentType,
    this.title,
    this.isLive = false,
  });

  final Uri url;

  /// MIME type, e.g. `video/mp4`, `application/x-mpegURL`, `image/jpeg`.
  final String contentType;
  final String? title;
  final bool isLive;

  /// Best-effort MIME type from a URL's extension, for the common formats
  /// Cast receivers play. Returns null when unknown so the UI can ask.
  static String? guessContentType(Uri url) {
    final path = url.path.toLowerCase();
    final dot = path.lastIndexOf('.');
    if (dot < 0) return null;
    return switch (path.substring(dot + 1)) {
      'mp4' || 'm4v' => 'video/mp4',
      'webm' => 'video/webm',
      'm3u8' => 'application/x-mpegURL',
      'mpd' => 'application/dash+xml',
      'mp3' => 'audio/mpeg',
      'm4a' || 'aac' => 'audio/mp4',
      'ogg' || 'oga' => 'audio/ogg',
      'flac' => 'audio/flac',
      'wav' => 'audio/wav',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => null,
    };
  }
}

enum TvPlayerState { idle, buffering, playing, paused }

/// What a casting device reports about the media it's playing.
class TvMediaStatus {
  const TvMediaStatus({
    required this.playerState,
    this.position = Duration.zero,
    this.duration,
    this.title,
    this.idleReason,
  });

  final TvPlayerState playerState;
  final Duration position;

  /// Null for live streams or before the receiver knows.
  final Duration? duration;
  final String? title;

  /// Why playback went idle (`FINISHED`, `ERROR`, `CANCELLED`,
  /// `INTERRUPTED`), when it did.
  final String? idleReason;

  bool get isActive => playerState != TvPlayerState.idle;
}

/// Implemented by providers whose devices play media from a URL (Google
/// Cast, and later DLNA). Separate from [TvProvider] because casting is a
/// capability, not a remote: the UI checks `TvCapabilities.casting` and
/// then talks to this, never to a concrete provider.
abstract interface class TvMediaCaster {
  Future<void> castMedia(TvMediaItem item);

  /// Emits whenever the device reports new playback state.
  Stream<TvMediaStatus?> get mediaStatus;

  Future<void> togglePlayback();
  Future<void> seek(Duration position);
  Future<void> stopMedia();
}
