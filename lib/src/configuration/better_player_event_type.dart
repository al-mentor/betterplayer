///Supported event types
enum BetterPlayerEventType {
  initialized,
  play,
  pause,
  seekTo,
  openFullscreen,
  hideFullscreen,
  setVolume,
  progress,
  finished,
  exception,
  controlsVisible,
  controlsHiddenStart,
  controlsHiddenEnd,
  setSpeed,
  changedSubtitles,
  changedTrack,
  changedPlayerVisibility,
  changedResolution,
  pipStart,
  pipStop,
  setupDataSource,
  bufferingStart,
  bufferingUpdate,
  bufferingEnd,
  changedPlaylistItem,
  setDuration,
  enteringPIP, // Fire when start PIP by tap button in UI and close app.
  exitingPIP, // Fire when start PIP by tap button in UI and open app from PIP.
  playInPIPTapped, // Android only. Fire when tap play button on PIP window.
  pauseInPIPTapped, //

}
