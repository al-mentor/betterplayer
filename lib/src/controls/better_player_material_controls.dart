import 'dart:async';
import 'dart:io';
import 'dart:math';


import 'package:better_player/src/configuration/better_player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:better_player/src/controls/better_player_controls_state.dart';
import 'package:better_player/src/controls/better_player_material_progress_bar.dart';
import 'package:better_player/src/controls/better_player_multiple_gesture_detector.dart';
import 'package:better_player/src/controls/better_player_progress_colors.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/video_player/video_player.dart';
// Flutter imports:
import 'package:flutter/material.dart';

import '../../better_player.dart';
import '../colors.dart';



class BetterPlayerMaterialControls extends StatefulWidget {
  ///Callback used to send information if player bar is hidden or not
  final Function(bool visbility) onControlsVisibilityChanged;

  ///Controls config
  final BetterPlayerControlsConfiguration controlsConfiguration;

  const BetterPlayerMaterialControls({
    required this.onControlsVisibilityChanged,
    required this.controlsConfiguration,
  });

  @override
  State<BetterPlayerMaterialControls> createState() {
    return _BetterPlayerMaterialControlsState();
  }
}

class _BetterPlayerMaterialControlsState
    extends BetterPlayerControlsState<BetterPlayerMaterialControls>
    with WidgetsBindingObserver {
  VideoPlayerValue? _latestValue;
  double? _latestVolume;
  Timer? _hideTimer;
  Timer? _initTimer;
  Timer? _showAfterExpandCollapseTimer;
  bool _wasLoading = false;
  VideoPlayerController? _controller;
  BetterPlayerController? _betterPlayerController;
  static StreamSubscription? _controlsVisibilityStreamSubscription;
  static StreamSubscription? _qualityVisibilityStreamSubscription;
  static StreamSubscription? _speedVisibilityStreamSubscription;

  BetterPlayerControlsConfiguration get _controlsConfiguration =>
      widget.controlsConfiguration;

  @override
  VideoPlayerValue? get latestValue => _latestValue;

  @override
  BetterPlayerController? get betterPlayerController => _betterPlayerController;

  @override
  BetterPlayerControlsConfiguration get betterPlayerControlsConfiguration =>
      _controlsConfiguration;

  // bool get isFullScreen =>
  //     MediaQuery.of(context).orientation == Orientation.landscape;
  @override
  Widget build(BuildContext context) {
    return buildLTRDirectionality(_buildMainWidget());
  }

  // void callSpeedSheetFunc() {
  //   callSpeedSheet();
  // }

  ///Builds main widget of the controls.
  Widget _buildMainWidget() {
    _wasLoading = isLoading(_latestValue);
    if (_latestValue?.hasError == true) {
      return Stack(
        children: [
          Container(
            color: Colors.black,
            child: _buildErrorWidget(),
          ),
           Positioned(
            top: 16,
            left: 16,
            child: BetterPlayerConstant.videoCloseIcon ,
          ),
        ],
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (BetterPlayerMultipleGestureDetector.of(context) != null) {
          BetterPlayerMultipleGestureDetector.of(context)!.onTap?.call();
        }
        controlsNotVisible
            ? cancelAndRestartTimer()
            : changePlayerControlsNotVisible(true);
      },
      onDoubleTap: () {
        if (BetterPlayerMultipleGestureDetector.of(context) != null) {
          BetterPlayerMultipleGestureDetector.of(context)!.onDoubleTap?.call();
        }
        cancelAndRestartTimer();
      },
      onLongPress: () {
        if (BetterPlayerMultipleGestureDetector.of(context) != null) {
          BetterPlayerMultipleGestureDetector.of(context)!.onLongPress?.call();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_wasLoading)
            Center(child: _buildLoadingWidget())
          else
            _buildHitArea(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),
          Positioned(
            bottom: 0,
            left: 0.0,
            right: 0.0,
            child: _buildBottomBar(),
          ),
          Positioned(
            right: 0,
            bottom: _controlsConfiguration.controlBarHeight,
            width: MediaQuery.of(context).size.width * 0.4,
            child: _buildNextVideoWidget(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _dispose();
  }

  void _dispose() {
    //changePlayerControlsNotVisible(false);
    _controller?.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
    _controlsVisibilityStreamSubscription?.cancel();
    _qualityVisibilityStreamSubscription?.cancel();
  }

  @override
  void didChangeDependencies() {
    final oldController = _betterPlayerController;
    _betterPlayerController = BetterPlayerController.of(context);
    _controller = _betterPlayerController!.videoPlayerController;
    _latestValue = _controller!.value;

    if (oldController != _betterPlayerController) {
      _dispose();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initialize();
      });
    }

    super.didChangeDependencies();
  }

  Widget _buildErrorWidget() {
    final errorBuilder =
        _betterPlayerController!.betterPlayerConfiguration.errorBuilder;
    if (errorBuilder != null) {
      return errorBuilder(
          context,
          _betterPlayerController!
              .videoPlayerController!.value.errorDescription);
    } else {
      final textStyle = TextStyle(color: _controlsConfiguration.textColor);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning,
              color: _controlsConfiguration.iconsColor,
              size: 42,
            ),
            Text(
              _betterPlayerController!.translations.generalDefaultError,
              style: textStyle,
            ),
            if (_controlsConfiguration.enableRetry)
              TextButton(
                onPressed: () {
                  _betterPlayerController!.retryDataSource();
                },
                child: Text(
                  _betterPlayerController!.translations.generalRetry,
                  style: textStyle.copyWith(fontWeight: FontWeight.bold),
                ),
              )
          ],
        ),
      );
    }
  }

  Widget _buildTopBar() {
    if (!betterPlayerController!.controlsEnabled) {
      return const SizedBox();
    }
    // final isFullScreen =
    //     MediaQuery.of(context).orientation == Orientation.landscape;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: (_controlsConfiguration.enableOverflowMenu)
          ? SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!(betterPlayerController?.isPIPStart ?? false))
                    if (_controlsConfiguration
                                .topBarEndWidgetWhenVideoIsNotLocked !=
                            null ||
                        _controlsConfiguration
                                .topBarEndWidgetWhenVideoIsLocked !=
                            null) ...[
                      !controlsNotVisible
                          ? (_controlsConfiguration
                                  .topBarEndWidgetWhenVideoIsNotLocked ??
                              const SizedBox.shrink())
                          : (_controlsConfiguration
                                  .topBarEndWidgetWhenVideoIsLocked ??
                              const SizedBox.shrink())
                    ],
                  const Spacer(),
                  if (_controlsConfiguration.topBarCenterWidget != null &&
                      _betterPlayerController!.isFullScreen) ...[
                    AnimatedOpacity(
                        opacity: controlsNotVisible ? 0.0 : 1.0,
                        duration: _controlsConfiguration.controlsHideTime,
                        onEnd: _onPlayerHide,
                        child: _controlsConfiguration.topBarCenterWidget!),
                  ],
                  const Spacer(),
                  if (_controlsConfiguration.enablePip)
                    _buildPipButtonWrapperWidget(
                        controlsNotVisible, _onPlayerHide)
                  else
                    const SizedBox(),
                  if (betterPlayerController!.isFullScreen &&
                      _controlsConfiguration
                          .disableBuildMoreWidgetWhenFullScreen)
                    const SizedBox.shrink()
                  else
                    AbsorbPointer(
                      absorbing: controlsNotVisible,
                      child: AnimatedOpacity(
                          opacity: controlsNotVisible ? 0.0 : 1.0,
                          duration: _controlsConfiguration.controlsHideTime,
                          onEnd: _onPlayerHide,
                          child: _buildMoreButton()),
                    ),
                ],
              ),
            )
          : const SizedBox(),
    );
  }

  Widget _buildPipButton() {
    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        betterPlayerController!.enablePictureInPicture(
            betterPlayerController!.betterPlayerGlobalKey!);
      },
      padding: const EdgeInsets.all(8.0),
      child: Icon(
        betterPlayerControlsConfiguration.pipMenuIcon,
        color: betterPlayerControlsConfiguration.iconsColor,
      ),
    );
  }

  Widget _buildPipButtonWrapperWidget(
      bool hideStuff, void Function() onPlayerHide) {
    //  if (!Platform.isIOS) {
    return const SizedBox.shrink();
    //}
    // return FutureBuilder<bool>(
    //   future: betterPlayerController!.isPictureInPictureSupported(),
    //   builder: (context, snapshot) {
    //     final bool isPipSupported = snapshot.data ?? false;
    //     if (isPipSupported &&
    //         _betterPlayerController!.betterPlayerGlobalKey != null) {
    //       return AnimatedOpacity(
    //         opacity: hideStuff ? 0.0 : 1.0,
    //         duration: betterPlayerControlsConfiguration.controlsHideTime,
    //         onEnd: onPlayerHide,
    //         child: Container(
    //           child: Row(
    //             mainAxisAlignment: MainAxisAlignment.end,
    //             children: [
    //               _buildPipButton(),
    //             ],
    //           ),
    //         ),
    //       );
    //     } else {
    //       return const SizedBox();
    //     }
    //   },
    // );
  }

  Widget _buildMoreButton() {
    return Row(
      children: [
        IconButton(
          //padding: const EdgeInsets.all(8.0),
          onPressed: () {
            onShowMoreClicked();
          },
          icon: _controlsConfiguration.overflowMenuWidget ??
              Icon(
                _controlsConfiguration.overflowMenuIcon,
                color: _controlsConfiguration.iconsColor,
                size: 35.0,
              ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final isFullScreen = betterPlayerController!.isFullScreen;
    // if (!betterPlayerController!.controlsEnabled) {
    //   return const SizedBox();
    // }
    return ListenableBuilder(
      listenable: _controller!,
      builder: (context, child) => AnimatedCrossFade(
        alignment: Alignment.bottomCenter,
        crossFadeState: controlsNotVisible
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: _controlsConfiguration.controlsHideTime,
        //onEnd: _onPlayerHide,
        secondChild: _buildStickyProgressBar(),
        firstChild: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              if (betterPlayerController!.controlsEnabled)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      _buildPosition(),
                      if (!_betterPlayerController!.isLiveStream() &&
                          _controlsConfiguration.enableProgressBar)
                        _buildProgressBar(),
                      _buildDuration(),
                      if (_controlsConfiguration.enableMute)
                        _buildMuteButton(_controller)
                      else
                        const SizedBox(),
                      if (_controlsConfiguration.enableFullscreen)
                        _buildExpandButton()
                      else
                        const SizedBox(),
                    ],
                  ),
                ),
              if (_controlsConfiguration.fullScreenControlsBuilder != null &&
                  isFullScreen &&
                  !_betterPlayerController!.isPIPStart) ...[
                _controlsConfiguration.fullScreenControlsBuilder!.call(context),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveWidget() {
    return Text(
      _betterPlayerController!.translations.controlsLive,
      style: TextStyle(
          color: _controlsConfiguration.liveTextColor,
          fontWeight: FontWeight.bold),
    );
  }

  Widget _buildExpandButton() {
    return BetterPlayerMaterialClickableWidget(
      onTap: _onExpandCollapse,
      raduis: _controlsConfiguration.fullScreenIconWidget != null ? 0 : null,
      child: AnimatedOpacity(
        opacity: controlsNotVisible ? 0.0 : 1.0,
        duration: _controlsConfiguration.controlsHideTime,
        child: _controlsConfiguration.fullScreenIconWidget ??
            Container(
              height: _controlsConfiguration.controlBarHeight,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Icon(
                  _betterPlayerController!.isFullScreen
                      ? _controlsConfiguration.fullscreenDisableIcon
                      : _controlsConfiguration.fullscreenEnableIcon,
                  color: _controlsConfiguration.iconsColor,
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildHitArea() {
    if (!betterPlayerController!.controlsEnabled) {
      return const SizedBox();
    }
    return AbsorbPointer(
      absorbing: controlsNotVisible,
      child: Container(
        child: Center(
          child: AnimatedOpacity(
            opacity: controlsNotVisible ? 0.0 : 1.0,
            duration: _controlsConfiguration.controlsHideTime,
            child: _buildMiddleRow(),
          ),
        ),
      ),
    );
  }

  Widget _buildMiddleRow() {
    return Container(
      color: _controlsConfiguration.controlBarColor,
      width: double.infinity,
      height: double.infinity,
      child: _betterPlayerController?.isLiveStream() == true
          ? const SizedBox()
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_controlsConfiguration.enableSkips)
                  Flexible(child: _buildSkipButton()),
                Flexible(child: _buildReplayButton(_controller!)),
                if (_controlsConfiguration.enableSkips)
                  Flexible(child: _buildForwardButton()),
              ],
            ),
    );
  }

  Widget _buildHitAreaClickableButton(
      {Widget? icon, required void Function() onClicked}) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 80.0, maxWidth: 80.0),
      child: BetterPlayerMaterialClickableWidget(
        onTap: onClicked,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: icon,
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return _buildHitAreaClickableButton(
      icon: _controlsConfiguration.skipBackIconWidget,
      onClicked: skipBack,
    );
  }

  Widget _buildForwardButton() {
    return _buildHitAreaClickableButton(
      icon: _controlsConfiguration.skipForwardIconWidget,
      onClicked: skipForward,
    );
  }

  Widget _buildReplayButton(VideoPlayerController controller) {
    // final bool isFinished =
    return _buildHitAreaClickableButton(
      icon: isVideoFinished(_latestValue)
          ? Icon(
              Icons.replay,
              size: 42,
              color: _controlsConfiguration.iconsColor,
            )
          : Icon(
              controller.value.isPlaying
                  ? _controlsConfiguration.pauseIcon
                  : _controlsConfiguration.playIcon,
              size: 42,
              color: _controlsConfiguration.iconsColor,
            ),
      onClicked: () {
        _onPlayPause();
        // if (isVideoFinished(_latestValue)) {
        //   print("isVideoFinished");
        //   if (_latestValue != null && _latestValue!.isPlaying) {
        //     print("_latestValue");
        //     if (_displayTapped) {
        //       print("_displayTapped");
        //       changePlayerControlsNotVisible(true);
        //     } else {
        //       print("false _displayTapped");
        //       cancelAndRestartTimer();
        //     }
        //   } else {
        //     print("false _latestValue");
        //     _onPlayPause();
        //     changePlayerControlsNotVisible(true);
        //   }
        // } else {
        //   print("false isVideoFinished");
        //   _onPlayPause();
        // }
      },
    );
  }

  Widget _buildNextVideoWidget() {
    return StreamBuilder<int?>(
      stream: _betterPlayerController!.nextVideoTimeStream,
      builder: (context, snapshot) {
        final time = snapshot.data;
        if (time != null && time > 0) {
          return BetterPlayerMaterialClickableWidget(
            onTap: () {
              _betterPlayerController!.playNextVideo();
            },
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                // margin: EdgeInsets.only(
                //   bottom: _controlsConfiguration.controlBarHeight - 20,
                //   right: 24,
                // ),
                decoration: BoxDecoration(
                  color: _controlsConfiguration.controlBarColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: FittedBox(
                    child: Text(
                      "${_betterPlayerController!.translations.controlsNextVideoIn} $time",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget _buildMuteButton(
    VideoPlayerController? controller,
  ) {
    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        cancelAndRestartTimer();
        if (_latestValue!.volume == 0) {
          _betterPlayerController!.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller!.value.volume;
          _betterPlayerController!.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: controlsNotVisible ? 0.0 : 1.0,
        duration: _controlsConfiguration.controlsHideTime,
        child: ClipRect(
          child: Container(
            height: _controlsConfiguration.controlBarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              (_latestValue != null && _latestValue!.volume > 0)
                  ? _controlsConfiguration.muteIcon
                  : _controlsConfiguration.unMuteIcon,
              color: _controlsConfiguration.iconsColor,
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildPlayPause(VideoPlayerController controller) {
  //   return BetterPlayerMaterialClickableWidget(
  //     key: const Key("better_player_material_controls_play_pause_button"),
  //     onTap: _onPlayPause,
  //     child: Container(
  //       height: double.infinity,
  //       margin: const EdgeInsets.symmetric(horizontal: 4),
  //       padding: const EdgeInsets.symmetric(horizontal: 12),
  //       child: Icon(
  //         controller.value.isPlaying
  //             ? _controlsConfiguration.pauseIcon
  //             : _controlsConfiguration.playIcon,
  //         color: _controlsConfiguration.iconsColor,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildPosition() {
    final position =
        _latestValue != null ? _latestValue!.position : Duration.zero;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: RichText(
        text: TextSpan(
          text: BetterPlayerUtils.formatDuration(position),
          style: TextStyle(
            fontSize: 12.0,
            color: _controlsConfiguration.textColor,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDuration() {
    final duration = _latestValue != null && _latestValue!.duration != null
        ? _latestValue!.duration!
        : Duration.zero;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 12.0,
            color: _controlsConfiguration.textColor,
            decoration: TextDecoration.none,
          ),
          children: <TextSpan>[
            TextSpan(
              text: BetterPlayerUtils.formatDuration(duration),
              style: TextStyle(
                fontSize: 12.0,
                color: _controlsConfiguration.textColor,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    changePlayerControlsNotVisible(false);
  }

  Future<void> _initialize() async {
    _controller!.addListener(_updateState);
    // changePlayerControlsNotVisible(true);
    //_updateState();

    if ((_controller!.value.isPlaying) ||
        _betterPlayerController!.betterPlayerConfiguration.autoPlay) {
      _startHideTimer();
    }

    if (_controlsConfiguration.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        changePlayerControlsNotVisible(false);
      });
    }

    _controlsVisibilityStreamSubscription =
        _betterPlayerController!.controlsVisibilityStream.listen((state) {
      changePlayerControlsNotVisible(!state);
      if (!controlsNotVisible) {
        cancelAndRestartTimer();
      }
    });

    await _qualityVisibilityStreamSubscription?.cancel();
    await _speedVisibilityStreamSubscription?.cancel();

    _qualityVisibilityStreamSubscription =
        _betterPlayerController!.qualityVisibilityStream.listen((state) {
      showQualityBottomSheet(state);
    });

    _speedVisibilityStreamSubscription =
        _betterPlayerController!.speedVisibilityStream.listen((state) {
      callSpeedSheet();
    });
  }

  void _onExpandCollapse() {
    changePlayerControlsNotVisible(true);
    _betterPlayerController!.toggleFullScreen();
    // _showAfterExpandCollapseTimer =
    //     Timer(_controlsConfiguration.controlsHideTime, () {
    //   //  setState(() {
    //   cancelAndRestartTimer();
    //   // });
    // });
  }

  void _onPlayPause() {
    bool isFinished = false;

    if (_latestValue?.position != null && _latestValue?.duration != null) {
      isFinished = _latestValue!.position >= _latestValue!.duration!;
    }

    if (_controller!.value.isPlaying) {
      changePlayerControlsNotVisible(false);
      _hideTimer?.cancel();
      _betterPlayerController!.pause();
      _initTimer?.cancel();
    } else {
      cancelAndRestartTimer();

      if (!_controller!.value.initialized) {
      } else {
        if (isFinished) {
          _betterPlayerController!.seekTo(const Duration());
          changePlayerControlsNotVisible(true);
          //_controller?.addListener(_updateState);
          //_dispose();
          //  setState(() {
          // _initialize();
          // });
          return;
        }
        _betterPlayerController!.play();
        _betterPlayerController!.cancelNextVideoTimer();
      }
    }
  }

  void _startHideTimer() {
    if (_betterPlayerController!.controlsAlwaysVisible) {
      return;
    }
    _hideTimer = Timer(const Duration(milliseconds: 4000), () {
      changePlayerControlsNotVisible(true);
    });
  }

  void _updateState() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!controlsNotVisible ||
            isVideoFinished(_controller!.value) ||
            _wasLoading ||
            isLoading(_controller!.value) &&
                betterPlayerController!.isPlaying()!) {
          if (mounted) {
            setState(() {
              _latestValue = _controller!.value;
              if (isVideoFinished(_latestValue) &&
                  _betterPlayerController?.isLiveStream() == false &&
                  betterPlayerController!.isPlaying()!) {
                changePlayerControlsNotVisible(false);
                _hideTimer?.cancel();
                _initTimer?.cancel();
                _showAfterExpandCollapseTimer?.cancel();
                _betterPlayerController!.pause();
                //_dispose();
                // _hideTimer?.cancel();
                // _initTimer?.cancel();
                //_controller?.removeListener(_updateState);
              }
            });
          }
        }
      });
    }
  }

  int? seekDurationViewOnly;
  Widget _buildProgressBar() {
    final controller = _controller!;
    final positionInSeconds = controller.value.position.inSeconds;
    final bufferedAfter = controller.value.buffered
        .where((element) => element.end.inSeconds > positionInSeconds);
    double? bufferValue;
    if (bufferedAfter.isNotEmpty) {
      if (bufferedAfter.length == 1) {
        bufferValue = bufferedAfter.elementAt(0).end.inSeconds.toDouble();
      } else {
        bufferValue =
            bufferedAfter.map((e) => e.end.inSeconds).reduce(max).toDouble();
      }
    }
    if (!controller.value.initialized) {
      return const Expanded(
        child: SizedBox(),
      );
    }

    final maxDuration = controller.value.duration?.inSeconds.toDouble() ?? 1;
    if (maxDuration != 1 && positionInSeconds > maxDuration) {
      _betterPlayerController
          ?.seekTo(const Duration())
          .then((value) => controller.play());
    }

    return Expanded(
      child: SizedBox(
        height: 50.0,
        child: Slider(
          value:
              seekDurationViewOnly?.toDouble() ?? positionInSeconds.toDouble(),
          secondaryTrackValue:
              bufferValue != null ? min(maxDuration, bufferValue) : null,
          max: maxDuration,
          onChanged: (v) {
            if (!Platform.isIOS) {
              _betterPlayerController?.seekTo(Duration(seconds: v.toInt()));
            } else {
              if (seekDurationViewOnly != null) {
                setState(() {
                  seekDurationViewOnly = v.toInt();
                });
              }
            }
          },
          onChangeStart: (v) {
            if (Platform.isIOS) {
              seekDurationViewOnly = v.toInt();
            }
            _hideTimer?.cancel();
          },
          onChangeEnd: (v) async {
            if (Platform.isIOS) {
              _betterPlayerController
                  ?.seekTo(Duration(seconds: v.toInt()))
                  .then((value) {
                setState(() {
                  seekDurationViewOnly = null;
                });
              });
            }
            while (controller.value.isBuffering) {
              await Future.delayed(const Duration(milliseconds: 200));
            }
            cancelAndRestartTimer();
          },
          activeColor: _controlsConfiguration.progressBarPlayedColor,
          secondaryActiveColor: _controlsConfiguration.progressBarBufferedColor,
          inactiveColor: Pallete.gray4,
        ),
      ),
    );
  }

  Widget _buildStickyProgressBar() {
    if (betterPlayerController!.isFullScreen) {
      return const SizedBox.shrink();
    }
    return BetterPlayerMaterialVideoProgressBar(
      _controller,
      _betterPlayerController,
      height: 8.0,
      colors: BetterPlayerProgressColors(
          playedColor: _controlsConfiguration.progressBarPlayedColor,
          handleColor: Colors.transparent,
          bufferedColor: _controlsConfiguration.progressBarBufferedColor,
          backgroundColor: Pallete.gray4),
    );
  }

  void _onPlayerHide() {
    _betterPlayerController!.toggleControlsVisibility(!controlsNotVisible);
    widget.onControlsVisibilityChanged(!controlsNotVisible);
  }

  Widget? _buildLoadingWidget() {
    if (_controlsConfiguration.loadingWidget != null) {
      return Container(
        color: _controlsConfiguration.controlBarColor,
        child: _controlsConfiguration.loadingWidget,
      );
    }

    return CircularProgressIndicator(
      valueColor:
          AlwaysStoppedAnimation<Color>(_controlsConfiguration.loadingColor),
    );
  }
}
