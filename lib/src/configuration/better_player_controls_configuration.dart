import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

///UI configuration of Better Player. Allows to change colors/icons/behavior
///of controls. Used in BetterPlayerConfiguration. Configuration applies only
///for player displayed in app, not in notification or PiP mode.
class BetterPlayerControlsConfiguration {
  ///Color of the control bars
  final Color controlBarColor;

  ///Color of texts
  final Color textColor;

  ///Color of icons
  final Color iconsColor;

  ///Icon of play
  final IconData playIcon;

  ///Icon of pause
  final IconData pauseIcon;

  ///Icon of mute
  final IconData muteIcon;

  ///Icon of unmute
  final IconData unMuteIcon;

  ///Icon of fullscreen mode enable
  final IconData fullscreenEnableIcon;

  ///Icon of fullscreen mode disable
  final IconData fullscreenDisableIcon;


  ///Flag used to enable/disable fullscreen
  final bool enableFullscreen;

  ///Flag used to enable/disable mute
  final bool enableMute;

  ///Flag used to enable/disable progress texts
  final bool enableProgressText;

  ///Flag used to enable/disable progress bar
  final bool enableProgressBar;

  ///Flag used to enable/disable progress bar drag
  final bool enableProgressBarDrag;

  ///Flag used to enable/disable play-pause
  final bool enablePlayPause;

  ///Flag used to enable skip forward and skip back
  final bool enableSkips;

  ///Progress bar played color
  final Color progressBarPlayedColor;

  ///Progress bar circle color
  final Color progressBarHandleColor;

  ///Progress bar buffered video color
  final Color progressBarBufferedColor;

  ///Progress bar background color
  final Color progressBarBackgroundColor;

  ///Time to hide controls
  final Duration controlsHideTime;

  ///Parameter used to build custom controls
  final Widget Function(BetterPlayerController controller,
      Function(bool) onPlayerVisibilityChanged)? customControlsBuilder;

  ///Parameter used to change theme of the player
  final BetterPlayerTheme? playerTheme;

  ///Flag used to show/hide controls
  final bool showControls;

  ///Flag used to show controls on init
  final bool showControlsOnInitialize;

  ///Control bar height
  final double controlBarHeight, topBarHeight, bottomBarHeight;

  ///Live text color;
  final Color liveTextColor;

  ///Flag used to show/hide overflow menu which contains playback, subtitles,
  ///qualities options.
  final bool enableOverflowMenu;

  ///Flag used to show/hide playback speed
  final bool enablePlaybackSpeed;

  ///Flag used to show/hide subtitles
  final bool enableSubtitles;

  ///Flag used to show/hide qualities
  final bool enableQualities;

  ///Flag used to show/hide PiP mode
  final bool enablePip;

  ///Flag used to enable/disable retry feature
  final bool enableRetry;

  ///Flag used to show/hide audio tracks
  final bool enableAudioTracks;

  ///Custom items of overflow menu
  final List<BetterPlayerOverflowMenuItem> overflowMenuCustomItems;

  ///Icon of the overflow menu
  final IconData overflowMenuIcon;

  ///Icon of the PiP menu
  final IconData pipMenuIcon;

  ///Icon of the playback speed menu item from overflow menu
  final IconData playbackSpeedIcon;

  ///Icon of the subtitles menu item from overflow menu
  final IconData subtitlesIcon;

  ///Icon of the qualities menu item from overflow menu
  final IconData qualitiesIcon;

  ///Icon of the audios menu item from overflow menu
  final IconData audioTracksIcon;

  ///Color of overflow menu icons
  final Color overflowMenuIconsColor;

  ///Time which will be used once user uses forward
  final int forwardSkipTimeInMilliseconds;

  ///Time which will be used once user uses backward
  final int backwardSkipTimeInMilliseconds;

  ///Color of default loading indicator
  final Color loadingColor;

  ///Widget which can be used instead of default progress
  final Widget? loadingWidget;

  ///Color of the background, when no frame is displayed.
  final Color backgroundColor;

  ///Color of the bottom modal sheet used for overflow menu items.
  final Color overflowModalColor;

  ///Color of text in bottom modal sheet used for overflow menu items.
  final Color overflowModalTextColor;
  final Color overflowModalSelectedIconColor;
  final double? internetSpeed;
  final Widget? fullScreenIconWidget,
      topBarEndWidgetWhenVideoIsNotLocked,
      topBarEndWidgetWhenVideoIsLocked,
      topBarCenterWidget,
      overflowMenuWidget,
      skipBackIconWidget,
      skipForwardIconWidget;
  final EdgeInsets? fullScreenIconPadding;
  final bool disableBuildMoreWidgetWhenFullScreen;
  final void Function()? onFullScreenIconWidgetTapped;
  final String? trackDesc;

  final Widget Function(BuildContext)? fullScreenControlsBuilder;

  const BetterPlayerControlsConfiguration(
      {this.fullScreenControlsBuilder,
      this.skipBackIconWidget,
      this.skipForwardIconWidget,
      this.controlBarColor = Colors.black87,
      this.textColor = Colors.white,
      this.iconsColor = Colors.white,
      this.playIcon = Icons.play_arrow_outlined,
      this.pauseIcon = Icons.pause_outlined,
      this.muteIcon = Icons.volume_up_outlined,
      this.unMuteIcon = Icons.volume_off_outlined,
      this.fullscreenEnableIcon = Icons.fullscreen_outlined,
      this.fullscreenDisableIcon = Icons.fullscreen_exit_outlined,
      this.enableFullscreen = true,
      this.enableMute = true,
      this.enableProgressText = true,
      this.enableProgressBar = true,
      this.enableProgressBarDrag = true,
      this.enablePlayPause = true,
      this.enableSkips = true,
      this.enableAudioTracks = true,
      this.progressBarPlayedColor = Colors.white,
      this.progressBarHandleColor = Colors.white,
      this.progressBarBufferedColor = Colors.white70,
      this.progressBarBackgroundColor = Colors.white60,
      this.controlsHideTime = const Duration(milliseconds: 300),
      this.customControlsBuilder,
      this.playerTheme,
      this.showControls = true,
      this.showControlsOnInitialize = true,
      this.controlBarHeight = 48.0,
      this.liveTextColor = Colors.red,
      this.enableOverflowMenu = true,
      this.enablePlaybackSpeed = true,
      this.enableSubtitles = true,
      this.enableQualities = true,
      this.enablePip = true,
      this.enableRetry = true,
      this.overflowMenuCustomItems = const [],
      this.overflowMenuIcon = Icons.more_vert_outlined,
      this.pipMenuIcon = Icons.picture_in_picture_outlined,
      this.playbackSpeedIcon = Icons.shutter_speed_outlined,
      this.qualitiesIcon = Icons.hd_outlined,
      this.subtitlesIcon = Icons.closed_caption_outlined,
      this.audioTracksIcon = Icons.audiotrack_outlined,
      this.overflowMenuIconsColor = Colors.black,
      this.forwardSkipTimeInMilliseconds = 10000,
      this.backwardSkipTimeInMilliseconds = 10000,
      this.loadingColor = Colors.white,
      this.loadingWidget,
      this.backgroundColor = Colors.black,
      this.overflowModalColor = Colors.white,
      this.overflowModalTextColor = Colors.black,
      this.overflowModalSelectedIconColor = Colors.blue,
      this.fullScreenIconWidget,
      this.topBarCenterWidget,
      this.topBarEndWidgetWhenVideoIsNotLocked,
      this.topBarHeight = 48,
      this.bottomBarHeight = 48,
      this.overflowMenuWidget,
      this.disableBuildMoreWidgetWhenFullScreen = true,
      this.onFullScreenIconWidgetTapped,
      this.fullScreenIconPadding,
      this.topBarEndWidgetWhenVideoIsLocked,
      this.internetSpeed,
      this.trackDesc,
      });


BetterPlayerControlsConfiguration copyWith({
    Widget? skipBackIconWidget,
    Widget? skipForwardIconWidget,
    Color? controlBarColor,
    Color? textColor,
    Color? iconsColor,
    IconData? playIcon,
    IconData? pauseIcon,
    IconData? muteIcon,
    IconData? unMuteIcon,
    IconData? fullscreenEnableIcon,
    IconData? fullscreenDisableIcon,
    bool? enableFullscreen,
    bool? enableMute,
    bool? enableProgressText,
    bool? enableProgressBar,
    bool? enableProgressBarDrag,
    bool? enablePlayPause,
    bool? enableSkips,
    Color? progressBarPlayedColor,
    Color? progressBarHandleColor,
    Color? progressBarBufferedColor,
    Color? progressBarBackgroundColor,
    Duration? controlsHideTime,
    Widget Function(BetterPlayerController controller, Function(bool) onPlayerVisibilityChanged)? customControlsBuilder,
    BetterPlayerTheme? playerTheme,
    bool? showControls,
    bool? showControlsOnInitialize,
    double? controlBarHeight,
    double? topBarHeight,
    double? bottomBarHeight,
    Color? liveTextColor,
    bool? enableOverflowMenu,
    bool? enablePlaybackSpeed,
    bool? enableSubtitles,
    bool? enableQualities,
    bool? enablePip,
    bool? enableRetry,
    bool? enableAudioTracks,
    List<BetterPlayerOverflowMenuItem>? overflowMenuCustomItems,
    IconData? overflowMenuIcon,
    IconData? pipMenuIcon,
    IconData? playbackSpeedIcon,
    IconData? subtitlesIcon,
    IconData? qualitiesIcon,
    IconData? audioTracksIcon,
    Color? overflowMenuIconsColor,
    int? forwardSkipTimeInMilliseconds,
    int? backwardSkipTimeInMilliseconds,
    Color? loadingColor,
    Widget? loadingWidget,
    Color? backgroundColor,
    Color? overflowModalColor,
    Color? overflowModalTextColor,
    Color? overflowModalSelectedIconColor,
    double? internetSpeed,
    Widget? fullScreenIconWidget,
    Widget? topBarCenterWidget,
    Widget? topBarEndWidgetWhenVideoIsNotLocked,
    Widget? topBarEndWidgetWhenVideoIsLocked,
    Widget? overflowMenuWidget,
    EdgeInsets? fullScreenIconPadding,
    bool? disableBuildMoreWidgetWhenFullScreen,
    void Function()? onFullScreenIconWidgetTapped,
    Widget Function(BuildContext)? fullScreenControlsBuilder,
    String? trackDesc,
}) {
    return BetterPlayerControlsConfiguration(
      //Solution
      skipBackIconWidget: skipBackIconWidget ?? this.skipBackIconWidget,
      skipForwardIconWidget: skipForwardIconWidget ?? this.skipForwardIconWidget,
        trackDesc : trackDesc ?? this.trackDesc,
        controlBarColor: controlBarColor ?? this.controlBarColor,
        textColor: textColor ?? this.textColor,
        iconsColor: iconsColor ?? this.iconsColor,
        playIcon: playIcon ?? this.playIcon,
        pauseIcon: pauseIcon ?? this.pauseIcon,
        muteIcon: muteIcon ?? this.muteIcon,
        unMuteIcon: unMuteIcon ?? this.unMuteIcon,
        fullscreenEnableIcon: fullscreenEnableIcon ?? this.fullscreenEnableIcon,
        fullscreenDisableIcon: fullscreenDisableIcon ?? this.fullscreenDisableIcon,
        enableFullscreen: enableFullscreen ?? this.enableFullscreen,
        enableMute: enableMute ?? this.enableMute,
        enableProgressText: enableProgressText ?? this.enableProgressText,
        enableProgressBar: enableProgressBar ?? this.enableProgressBar,
        enableProgressBarDrag: enableProgressBarDrag ?? this.enableProgressBarDrag,
        enablePlayPause: enablePlayPause ?? this.enablePlayPause,
        enableSkips: enableSkips ?? this.enableSkips,
        progressBarPlayedColor: progressBarPlayedColor ?? this.progressBarPlayedColor,
        progressBarHandleColor: progressBarHandleColor ?? this.progressBarHandleColor,
        progressBarBufferedColor: progressBarBufferedColor ?? this.progressBarBufferedColor,
        progressBarBackgroundColor: progressBarBackgroundColor ?? this.progressBarBackgroundColor,
        controlsHideTime: controlsHideTime ?? this.controlsHideTime,
        customControlsBuilder: customControlsBuilder ?? this.customControlsBuilder,
        playerTheme: playerTheme ?? this.playerTheme,
        showControls: showControls ?? this.showControls,
        showControlsOnInitialize: showControlsOnInitialize ?? this.showControlsOnInitialize,
        controlBarHeight: controlBarHeight ?? this.controlBarHeight,
        topBarHeight: topBarHeight ?? this.topBarHeight,
        bottomBarHeight: bottomBarHeight ?? this.bottomBarHeight,
        liveTextColor: liveTextColor ?? this.liveTextColor,
        enableOverflowMenu: enableOverflowMenu ?? this.enableOverflowMenu,
        enablePlaybackSpeed: enablePlaybackSpeed ?? this.enablePlaybackSpeed,
        enableSubtitles: enableSubtitles ?? this.enableSubtitles,
        enableQualities: enableQualities ?? this.enableQualities,
        enablePip: enablePip ?? this.enablePip,
        enableRetry: enableRetry ?? this.enableRetry,
        enableAudioTracks: enableAudioTracks ?? this.enableAudioTracks,
        overflowMenuCustomItems: overflowMenuCustomItems ?? this.overflowMenuCustomItems,
        overflowMenuIcon: overflowMenuIcon ?? this.overflowMenuIcon,
        pipMenuIcon: pipMenuIcon ?? this.pipMenuIcon,
        playbackSpeedIcon: playbackSpeedIcon ?? this.playbackSpeedIcon,
        subtitlesIcon: subtitlesIcon ?? this.subtitlesIcon,
        qualitiesIcon: qualitiesIcon ?? this.qualitiesIcon,
        audioTracksIcon: audioTracksIcon ?? this.audioTracksIcon,
        overflowMenuIconsColor: overflowMenuIconsColor ?? this.overflowMenuIconsColor,
        forwardSkipTimeInMilliseconds: forwardSkipTimeInMilliseconds ?? this.forwardSkipTimeInMilliseconds,
        backwardSkipTimeInMilliseconds: backwardSkipTimeInMilliseconds ?? this.backwardSkipTimeInMilliseconds,
        loadingColor: loadingColor ?? this.loadingColor,
        loadingWidget: loadingWidget ?? this.loadingWidget,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        overflowModalColor: overflowModalColor ?? this.overflowModalColor,
        overflowModalTextColor: overflowModalTextColor ?? this.overflowModalTextColor,
        overflowModalSelectedIconColor: overflowModalSelectedIconColor ?? this.overflowModalSelectedIconColor,
        internetSpeed: internetSpeed ?? this.internetSpeed,
        fullScreenIconWidget: fullScreenIconWidget ?? this.fullScreenIconWidget,
        topBarCenterWidget: topBarCenterWidget ?? this.topBarCenterWidget,
        topBarEndWidgetWhenVideoIsNotLocked: topBarEndWidgetWhenVideoIsNotLocked ?? this.topBarEndWidgetWhenVideoIsNotLocked,
        topBarEndWidgetWhenVideoIsLocked: topBarEndWidgetWhenVideoIsLocked ?? this.topBarEndWidgetWhenVideoIsLocked,
        overflowMenuWidget: overflowMenuWidget ?? this.overflowMenuWidget,
        fullScreenIconPadding: fullScreenIconPadding ?? this.fullScreenIconPadding,
        disableBuildMoreWidgetWhenFullScreen: disableBuildMoreWidgetWhenFullScreen ?? this.disableBuildMoreWidgetWhenFullScreen,
        onFullScreenIconWidgetTapped: onFullScreenIconWidgetTapped ?? this.onFullScreenIconWidgetTapped,
        fullScreenControlsBuilder: fullScreenControlsBuilder ?? this.fullScreenControlsBuilder,
    );
}

}
