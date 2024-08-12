import 'dart:math';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:better_player/src/controls/quality_extension.dart';
import 'package:better_player/src/controls/speed_widget_landscape.dart';
import 'package:better_player/src/core/video_speed_landscape_model.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

import '../better_player_constant.dart';
import '../colors.dart';

///Base class for both material and cupertino controls
abstract class BetterPlayerControlsState<T extends StatefulWidget> extends State<T> {
  ///Min. time of buffered video to hide loading timer (in milliseconds)
  static const int _bufferingInterval = 20000;

  BetterPlayerController? get betterPlayerController;

  BetterPlayerControlsConfiguration get betterPlayerControlsConfiguration;

  VideoPlayerValue? get latestValue;

  bool controlsNotVisible = true;

  void cancelAndRestartTimer();

  void showQualityBottomSheet(bool show) {
    if (show) _showQualitiesSelectionWidget();
  }

  bool isVideoFinished(VideoPlayerValue? videoPlayerValue) {
    return videoPlayerValue?.position != null &&
        videoPlayerValue?.duration != null &&
        videoPlayerValue!.position.inMilliseconds != 0 &&
        videoPlayerValue.duration!.inMilliseconds != 0 &&
        videoPlayerValue.position >= videoPlayerValue.duration!;
  }

  void callSpeedSheet() {
    _showSpeedChooserWidget();
  }

  void skipBack() {
    if (!(betterPlayerController?.isVideoInitialized() ?? false)) return;
    if (latestValue != null) {
      cancelAndRestartTimer();
      final beginning = const Duration().inMilliseconds;
      final skip = (latestValue!.position -
              Duration(milliseconds: betterPlayerControlsConfiguration.backwardSkipTimeInMilliseconds))
          .inMilliseconds;
      betterPlayerController!.seekTo(Duration(milliseconds: max(skip, beginning)));
      betterPlayerController!.setTrack(betterPlayerController!.betterPlayerAsmsTrack!);
    }
  }

  void skipForward() async {
    if (!(betterPlayerController?.isVideoInitialized() ?? false)) return;
    if (latestValue != null) {
      cancelAndRestartTimer();
      final end = latestValue!.duration!.inMilliseconds;
      final skip = (latestValue!.position +
              Duration(milliseconds: betterPlayerControlsConfiguration.forwardSkipTimeInMilliseconds))
          .inMilliseconds;
      if (skip > end) {
        await betterPlayerController!.seekTo(Duration(milliseconds: end - 50));
        betterPlayerController!.setTrack(betterPlayerController!.betterPlayerAsmsTrack!);
      } else {
        await betterPlayerController!.seekTo(Duration(milliseconds: min(skip, end)));
        betterPlayerController!.setTrack(betterPlayerController!.betterPlayerAsmsTrack!);
      }
    }
  }

  void onShowMoreClicked() {
    _showModalBottomSheet([_buildMoreOptionsList()]);
  }

  Widget _buildMoreOptionsList() {
    final translations = betterPlayerController!.translations;
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                    child: Center(
                        child: Text(
                  translations.properites,
                  style: const TextStyle(fontSize: 18),
                ))),
                InkWell(
                  child: const Icon(Icons.close),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          const Divider(
            color: Color(0xFF252525),
            height: 16.0,
            thickness: 2.0,
          ),
          if (betterPlayerControlsConfiguration.enablePlaybackSpeed && !betterPlayerController!.isFullScreen)
            _buildMoreOptionsListRow(
              betterPlayerControlsConfiguration.playbackSpeedIcon,
              translations.overflowMenuPlaybackSpeed,
              () {
                Navigator.of(context).pop();
                _showSpeedChooserWidget();
              },
              selectedValue: '${betterPlayerController!.videoPlayerController!.value.speed}x',
            ),
          _buildDivider(betterPlayerControlsConfiguration.enableSubtitles &&
              betterPlayerController!.betterPlayerSubtitlesSourceList.isNotEmpty),
          if (betterPlayerControlsConfiguration.enableSubtitles &&
              betterPlayerController!.betterPlayerSubtitlesSourceList.isNotEmpty)
            _buildMoreOptionsListRow(
                betterPlayerControlsConfiguration.subtitlesIcon, translations.overflowMenuSubtitles, () {
              Navigator.of(context).pop();
              _showSubtitlesSelectionWidget();
            }, selectedValue: getSelectedSubtitles(betterPlayerController!.betterPlayerSubtitlesSource)),
          _buildDivider(betterPlayerControlsConfiguration.enableQualities),
          if (betterPlayerControlsConfiguration.enableQualities)
            _buildMoreOptionsListRow(
              betterPlayerControlsConfiguration.qualitiesIcon,
              translations.overflowMenuQuality,
              () {
                Navigator.of(context).pop();
                _showQualitiesSelectionWidget();
              },
              selectedValue: betterPlayerController!.betterPlayerAsmsTrack?.qualityString(
                betterPlayerController!.translations,
              ),
            ),
          _buildDivider(betterPlayerControlsConfiguration.enableAudioTracks),
          if (betterPlayerControlsConfiguration.enableAudioTracks)
            _buildMoreOptionsListRow(
                betterPlayerControlsConfiguration.audioTracksIcon, translations.overflowMenuAudioTracks, () {
              Navigator.of(context).pop();
              _showAudioTracksSelectionWidget();
            }),
          if (betterPlayerControlsConfiguration.overflowMenuCustomItems.isNotEmpty)
            ...betterPlayerControlsConfiguration.overflowMenuCustomItems.map(
              (customItem) => _buildMoreOptionsListRow(
                customItem.icon,
                customItem.title,
                () {
                  Navigator.of(context).pop();
                  customItem.onClicked.call();
                },
              ),
            )
        ],
      ),
    );
  }

  Widget _buildMoreOptionsListRow(
    IconData icon,
    String name,
    void Function() onTap, {
    String? selectedValue,
  }) {
    selectedValue ??= betterPlayerController!.translations.qualityAuto;
    return BetterPlayerMaterialClickableWidget(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Visibility(
              visible: false,
              child: Icon(
                icon,
                color: betterPlayerControlsConfiguration.overflowMenuIconsColor,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              name,
              style: _getOverflowMenuElementTextStyle(false),
            ),
            const Expanded(child: SizedBox()),
            //  if (selectedValue != null)
            Text(
              selectedValue,
              style: _getOverflowMenuElementTextStyle(true).copyWith(
                color: const Color(0xFF0A8DB1),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  int? selectedSpeedIndex;
  final _speedList = <VideoSpeedModel>[
    const VideoSpeedModel(
      speedText: "2.0x",
      speedValue: 2,
      progressValue: 1000,
    ),
    const VideoSpeedModel(
      speedText: "1.5x",
      speedValue: 1.5,
      progressValue: 800,
    ),
    const VideoSpeedModel(
      speedText: "1.25x",
      speedValue: 1.25,
      progressValue: 600,
    ),
    const VideoSpeedModel(
      speedText: "1x",
      speedValue: 1,
      progressValue: 400,
    ),
    const VideoSpeedModel(
      speedText: "0.75x",
      speedValue: 0.75,
      progressValue: 200,
    ),
    const VideoSpeedModel(
      speedText: "0.5x",
      speedValue: 0.5,
      progressValue: 0,
    ),
  ];

  List<VideoSpeedModel> getSpeedList(BuildContext context) {
    return _speedList.reversed.toList(growable: false);
  }

  double get getSelectedSpeedIndex {
    if (BetterPlayerConstant.isRtl(context)) {
      return betterPlayerController!.videoPlayerController?.value.speed == 2
          ? 5
          : betterPlayerController!.videoPlayerController?.value.speed == 1.5
              ? 4
              : betterPlayerController!.videoPlayerController?.value.speed == 1.25
                  ? 3
                  : betterPlayerController!.videoPlayerController?.value.speed == 1
                      ? 2
                      : betterPlayerController!.videoPlayerController?.value.speed == 0.75
                          ? 1
                          : 0;
    } else {
      return betterPlayerController!.videoPlayerController?.value.speed == 2
          ? 0
          : betterPlayerController!.videoPlayerController?.value.speed == 1.5
              ? 1
              : betterPlayerController!.videoPlayerController?.value.speed == 1.25
                  ? 2
                  : betterPlayerController!.videoPlayerController?.value.speed == 1
                      ? 3
                      : betterPlayerController!.videoPlayerController?.value.speed == 0.75
                          ? 4
                          : 5;
    }
  }

  void _showSpeedChooserWidget() {
    setState(() {
      selectedSpeedIndex = getSelectedSpeedIndex.toInt();
    });
    betterPlayerController!.isFullScreen
        ? showModalBottomSheet(
            backgroundColor: Pallete.cards,
            isScrollControlled: false,
            isDismissible: false,
            enableDrag: false,
            context: context,
            builder: (_) => SpeedControllerBottomSheet(
                  onSpeedChanged: (index) {
                    // controller.selectedSpeedIndex(index);
                    final speedModel = getSpeedList(context)[index];
                    betterPlayerController?.videoPlayerController?.setSpeed(speedModel.speedValue);
                  },
                  speedList: getSpeedList(context),
                  videoSpeedIndicator: selectedSpeedIndex!.toDouble(),
                ))
        : _showModalBottomSheet([
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        betterPlayerController!.translations.speed,
                      ),
                    ),
                  ),
                  InkWell(
                    child: const Icon(Icons.close),
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            // _buildSpeedRow(0.25),
            const Divider(
              color: Color(0xFF252525),
              height: 16.0,
              thickness: 2.0,
            ),
            _buildSpeedRow(0.5),
            _buildDivider(true),
            _buildSpeedRow(0.75),
            _buildDivider(true),
            _buildSpeedRow(1.0),
            _buildDivider(true),
            _buildSpeedRow(1.25),
            _buildDivider(true),
            _buildSpeedRow(1.5),
            _buildDivider(true),
            // _buildSpeedRow(1.75),
            // _buildDivider(true),
            _buildSpeedRow(2.0),
          ]);
  }

  Widget _buildDivider(
    bool visibilty, {
    double? indent,
    double? endIndent,
    double? height,
  }) {
    return Visibility(
      visible: visibilty,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
        child: Divider(
          color: const Color(0xFF48484A),
          height: height,
          indent: indent,
          endIndent: endIndent,
          thickness: 1,
        ),
      ),
    );
  }

  Widget _buildSpeedRow(double value) {
    final bool isSelected = betterPlayerController!.videoPlayerController!.value.speed == value;
    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        Navigator.of(context).pop();
        betterPlayerController!.setSpeed(value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Text(
              "$value x",
              style: _getOverflowMenuElementTextStyle(isSelected),
            ),
            const Spacer(),
            Visibility(
              visible: isSelected,
              child: Image.asset(
                "assets/check_blue.png",
                height: 25.0,
                width: 25.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ///Latest value can be null
  bool isLoading(VideoPlayerValue? latestValue) {
    if (latestValue != null) {
      if (!latestValue.isPlaying && latestValue.duration == null) {
        return true;
      }

      final Duration position = latestValue.position;

      Duration? bufferedEndPosition;
      if (latestValue.buffered.isNotEmpty == true) {
        bufferedEndPosition = latestValue.buffered.last.end;
      }

      if (bufferedEndPosition != null) {
        final difference = bufferedEndPosition - position;

        if (latestValue.isPlaying && latestValue.isBuffering && difference.inMilliseconds < _bufferingInterval) {
          return true;
        }
      }
    }
    return false;
  }

  void _showSubtitlesSelectionWidget() {
    final subtitles = List.of(betterPlayerController!.betterPlayerSubtitlesSourceList);
    final noneSubtitlesElementExists =
        subtitles.firstWhereOrNull((source) => source.type == BetterPlayerSubtitlesSourceType.none) != null;
    if (!noneSubtitlesElementExists) {
      subtitles.add(BetterPlayerSubtitlesSource(type: BetterPlayerSubtitlesSourceType.none));
    }

    _showModalBottomSheet([
      Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    betterPlayerController!.translations.overflowMenuSubtitles,
                  ),
                ),
              ),
              InkWell(
                child: const Icon(Icons.close),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const Divider(
            color: Color(0xFF252525),
            height: 8.0,
            thickness: 2.0,
          ),
        ],
      ),
    ...subtitles.map((source) => _buildSubtitlesSourceRow(source)).toList()
    ]);
  }

  Widget _buildSubtitlesSourceRow(BetterPlayerSubtitlesSource subtitlesSource) {
    final selectedSourceType = betterPlayerController!.betterPlayerSubtitlesSource;
    final bool isSelected = (subtitlesSource == selectedSourceType) ||
        (subtitlesSource.type == BetterPlayerSubtitlesSourceType.none &&
            subtitlesSource.type == selectedSourceType!.type);

    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        Navigator.of(context).pop();
        betterPlayerController!.setupSubtitleSource(subtitlesSource);
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0,horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subtitlesSource.type == BetterPlayerSubtitlesSourceType.none
                      ? betterPlayerController!.translations.off
                      : subtitlesSource.nameLanguage(context) ?? betterPlayerController!.translations.generalDefault,
                  style: _getOverflowMenuElementTextStyle(isSelected),
                ),
                Visibility(
                  visible: isSelected,
                  child: Image.asset(
                    "assets/check_blue.png",
                    height: 25.0,
                    width: 25.0,
                  ),
                ),
              ],
            ),
          ),
          _buildDivider(true),
        ],
      ),
    );
  }

  ///Build both track and resolution selection
  ///Track selection is used for HLS / DASH videos
  ///Resolution selection is used for normal videos
  void _showQualitiesSelectionWidget() {
    if (!mounted) {
      return;
    }
    final orientation = MediaQuery.of(context).orientation;

    // HLS / DASH
    final List<String> asmsTrackNames = betterPlayerController!.betterPlayerDataSource!.asmsTrackNames ?? [];
    final List<BetterPlayerAsmsTrack> asmsTracks = Platform.isAndroid
        ? betterPlayerController!.betterPlayerAsmsTracks
        : betterPlayerController!.betterPlayerAsmsTracks.reversed.toList();

    final List<Widget> children = [
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (orientation == Orientation.portrait)
              Expanded(
                child: Center(
                  child: Text(
                    betterPlayerController!.translations.overflowMenuQuality,
                    style: DefaultTextStyle.of(context).style.copyWith(color: Pallete.whiteShColor),
                  ),
                ),
              )
            else
              Expanded(
                child: Row(
                  children: [
                    const SizedBox(width: 24),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        betterPlayerController!.translations.overflowMenuQuality,
                      ),
                    ),
                  ],
                ),
              ),
            InkWell(
              child: const Icon(Icons.close),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
      const Divider(
        color: Color(0xFF252525),
        height: 16.0,
        thickness: 2.0,
      ),
    ];

    if (Platform.isIOS) {
      for (var i = 0; i < asmsTracks.length; i++) {
        if (asmsTracks[i].height == 0) {
          asmsTracks.removeAt(i);
        }
      }
    }

    final autoTrack = _buildTrackRow(
        0, BetterPlayerAsmsTrack.defaultTrack(), betterPlayerController!.translations.qualityAuto, asmsTracks);

    // if (orientation == Orientation.landscape) {
    //   children.add(_buildDivider(
    //     true,
    //     height: 24,
    //     indent: 24,
    //     endIndent: 16,
    //     color: Colors.grey.withOpacity(0.3),
    //   ));
    // }
    if (autoTrack != null) {
      children.add(autoTrack);
      if (orientation == Orientation.portrait) {
        children.add(_buildDivider(true));
      }
    }

    for (var index = 0; index < asmsTracks.length; index++) {
      final track = asmsTracks[index];
      String preferredName = "";
      if (track.height == 0 && track.width == 0 && track.bitrate == 0) {
        preferredName = betterPlayerController!.translations.qualityAuto;
      } else {
        preferredName = asmsTrackNames.length > index ? asmsTrackNames[index] : "";
      }

      var data = _buildTrackRow(index + 1, asmsTracks[index], preferredName, asmsTracks);

      if (data != null) {
        children.add(data);
        bool showDivider = false;
        if (orientation == Orientation.portrait && index != (asmsTracks.length - 1)) {
          showDivider = true;
        }
        children.add(_buildDivider(showDivider));
      }
    }

    // normal videos
    final resolutions = betterPlayerController!.betterPlayerDataSource!.resolutions;
    resolutions?.forEach((String key, value) {
      var data = _buildResolutionSelectionRow(key, value);
      if (data != null) children.add(data);
    });

    if (children.isEmpty) {
      var data = _buildTrackRow(
          0, BetterPlayerAsmsTrack.defaultTrack(), betterPlayerController!.translations.qualityAuto, asmsTracks);
      if (data != null) {
        children.add(
          data,
        );
      }
    }

    _showModalBottomSheet(children);
  }

  Widget? _buildTrackRow(
      int index, BetterPlayerAsmsTrack track, String preferredName, List<BetterPlayerAsmsTrack> asmsTracks) {
    // final orientation = MediaQuery.of(context).orientation;
    //final int width = track.width ?? 0;
    final int height = track.height ?? 0;
    // final int bitrate = track.bitrate ?? 0;
    // final String mimeType = (track.mimeType ?? '').replaceAll('video/', '');
    // String trackName = preferredName;
    // String trackName = preferredName ??
    //     "${width}x$height ${BetterPlayerUtils.formatBitrate(bitrate)} $mimeType";
    String? trackDesc;
    if (track.height == 0) {
      // trackName = betterPlayerController!.translations.qualityAuto;
      trackDesc = betterPlayerController!.translations.qualityAuto;
    } else {
      if (height == 1080) {
        // trackName = betterPlayerController!.translations.fullHdQuality!;
        trackDesc = betterPlayerController!.translations.fullHdQualityDesc!;
      } else if (height == 720) {
        // trackName = betterPlayerController!.translations.hdQuality!;
        trackDesc = betterPlayerController!.translations.hdQualityDesc!;
      } else if (height == 180) {
        // trackName = betterPlayerController!.translations.lowQuality!;
        trackDesc = '${height}p'; //betterPlayerController!.translations.lowQualityDesc!;
      } else {
        // trackName = '$height';
        trackDesc =
            // (betterPlayerController!.translations.upToDesc).toString() + " " +
            '${height}p';
      }
    }

    // betterPlayerControlsConfiguration = betterPlayerControlsConfiguration.copyWith(
    //   trackDesc: trackDesc,z
    // );
    final selectedTrack = betterPlayerController!.betterPlayerAsmsTrack;
    // print("selectedTrack ${selectedTrack?.height}");
    // print("track ${track.height}");
    final bool isSelected = (selectedTrack?.height != null && selectedTrack?.height == height);

    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        Navigator.of(context).pop();
        betterPlayerController!.setTrack(track);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            // if (orientation == Orientation.landscape)
            //   Visibility(
            //     visible: isSelected,
            //     child: Image.asset(
            //       "assets/check_blue.png",
            //       height: 25.0,
            //       width: 25.0,
            //     ),
            //   ),
            // if (orientation == Orientation.landscape && !isSelected)
            //   const SizedBox(width: 24),
            const SizedBox(width: 8),
            Text(
              trackDesc,
              style: _getOverflowMenuElementTextStyle(true),
            ),
            // const SizedBox(width: 8),
            // Text(
            //   '$trackDesc',
            //   style: _getOverflowMenuElementTextStyle(false).copyWith(
            //     fontSize: 12,
            //   ),
            // ),
            const Spacer(),
            //if (orientation == Orientation.portrait)
            Visibility(
              visible: isSelected,
              child: Image.asset(
                "assets/check_blue.png",
                height: 25.0,
                width: 25.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildResolutionSelectionRow(String name, String url) {
    if (name.contains("480")) {
      name = "HD";
    } else if (name.contains("320")) {
      name = "Low quality";
    } else if (name.contains("1280")) {
      name = "Full HD";
    } else {
      return null;
    }

    final bool isSelected = url == betterPlayerController!.betterPlayerDataSource!.url;
    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        Navigator.of(context).pop();
        betterPlayerController!.setResolution(url);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            SizedBox(width: isSelected ? 8 : 16),
            Visibility(
              visible: isSelected,
              child: Image.asset(
                "assets/check_blue.png",
                height: 25.0,
                width: 25.0,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              name,
              style: _getOverflowMenuElementTextStyle(isSelected),
            ),
          ],
        ),
      ),
    );
  }

  void _showAudioTracksSelectionWidget() {
    //HLS / DASH
    final List<BetterPlayerAsmsAudioTrack>? asmsTracks = betterPlayerController!.betterPlayerAsmsAudioTracks;
    final List<Widget> children = [];
    final BetterPlayerAsmsAudioTrack? selectedAsmsAudioTrack = betterPlayerController!.betterPlayerAsmsAudioTrack;
    if (asmsTracks != null) {
      for (var index = 0; index < asmsTracks.length; index++) {
        final bool isSelected = selectedAsmsAudioTrack != null && selectedAsmsAudioTrack == asmsTracks[index];
        children.add(_buildAudioTrackRow(asmsTracks[index], isSelected));
      }
    }

    if (children.isEmpty) {
      children.add(
        _buildAudioTrackRow(
          BetterPlayerAsmsAudioTrack(
            label: betterPlayerController!.translations.generalDefault,
          ),
          true,
        ),
      );
    }

    _showModalBottomSheet(children);
  }

  Widget _buildAudioTrackRow(BetterPlayerAsmsAudioTrack audioTrack, bool isSelected) {
    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        Navigator.of(context).pop();
        betterPlayerController!.setAudioTrack(audioTrack);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            SizedBox(width: isSelected ? 8 : 16),
            Visibility(
              visible: isSelected,
              child: Image.asset(
                "assets/check_blue.png",
                height: 25.0,
                width: 25.0,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              audioTrack.label!,
              style: _getOverflowMenuElementTextStyle(isSelected),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _getOverflowMenuElementTextStyle(bool isSelected) {
    return TextStyle(
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      color: Pallete.whiteShColor,
    );
  }

  void _showModalBottomSheet(List<Widget> children) {
    _showMaterialBottomSheet(children);
  }

  void _showMaterialBottomSheet(List<Widget> children) {
    final size = MediaQuery.of(context).size;
    const backgroundColor = Pallete.cards;
    showModalBottomSheet<void>(
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      barrierColor: backgroundColor,
      isDismissible: false,
      enableDrag: false,
      context: context,
      useSafeArea: true,
      useRootNavigator: betterPlayerController?.betterPlayerConfiguration.useRootNavigator ?? false,
      builder: (context) {
        return Container(
          height: size.height,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: const BoxDecoration(
            color: Pallete.cards,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0),
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 16.0,
                ),
                ...children,
              ],
            ),
          ),
        );
      },
    );
  }

  ///Builds directionality widget which wraps child widget and forces left to
  ///right directionality.
  Widget buildLTRDirectionality(Widget child) {
    return Directionality(textDirection: TextDirection.ltr, child: child);
  }

  ///Called when player controls visibility should be changed.
  void changePlayerControlsNotVisible(bool notVisible) {
    if (mounted) {
      setState(() {
        if (notVisible) {
          betterPlayerController?.postEvent(BetterPlayerEvent(BetterPlayerEventType.controlsHiddenStart));
        }
        controlsNotVisible = notVisible;
      });
    }
  }

  String? getSelectedSubtitles(BetterPlayerSubtitlesSource? subtitlesSource) {
    return subtitlesSource?.nameLanguage(context);
  }
}
