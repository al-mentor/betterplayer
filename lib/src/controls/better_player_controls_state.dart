import 'dart:math';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:better_player/src/controls/quality_extension.dart';
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

///Base class for both material and cupertino controls
abstract class BetterPlayerControlsState<T extends StatefulWidget>
    extends State<T> {
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

  void skipBack() {
    if (latestValue != null) {
      cancelAndRestartTimer();
      final beginning = const Duration().inMilliseconds;
      final skip = (latestValue!.position -
              Duration(
                  milliseconds: betterPlayerControlsConfiguration
                      .backwardSkipTimeInMilliseconds))
          .inMilliseconds;
      betterPlayerController!
          .seekTo(Duration(milliseconds: max(skip, beginning)));
      betterPlayerController!
          .setTrack(betterPlayerController!.betterPlayerAsmsTrack!);
    }
  }

  void skipForward() {
    if (latestValue != null) {
      cancelAndRestartTimer();
      final end = latestValue!.duration!.inMilliseconds;
      final skip = (latestValue!.position +
              Duration(
                  milliseconds: betterPlayerControlsConfiguration
                      .forwardSkipTimeInMilliseconds))
          .inMilliseconds;
      betterPlayerController!.seekTo(Duration(milliseconds: min(skip, end)));
      betterPlayerController!
          .setTrack(betterPlayerController!.betterPlayerAsmsTrack!);
    }
  }

  void onShowMoreClicked() {
    _showModalBottomSheet([_buildMoreOptionsList()]);
  }

  Widget _buildMoreOptionsList() {
    final translations = betterPlayerController!.translations;
    return SingleChildScrollView(
      // ignore: avoid_unnecessary_containers
      child: Container(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 0.16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                      child: Center(
                          child: Text(
                    translations.properites,
                    style: TextStyle(fontSize: 18),
                  ))),
                  InkWell(
                    child: Icon(Icons.close),
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (betterPlayerControlsConfiguration.enablePlaybackSpeed)
              _buildMoreOptionsListRow(
                betterPlayerControlsConfiguration.playbackSpeedIcon,
                translations.overflowMenuPlaybackSpeed,
                () {
                  Navigator.of(context).pop();
                  _showSpeedChooserWidget();
                },
                selectedValue:
                    '${betterPlayerController!.videoPlayerController!.value.speed}x',
              ),
            _buildDivider(betterPlayerControlsConfiguration.enableSubtitles),
            if (betterPlayerControlsConfiguration.enableSubtitles)
              _buildMoreOptionsListRow(
                  betterPlayerControlsConfiguration.subtitlesIcon,
                  translations.overflowMenuSubtitles, () {
                Navigator.of(context).pop();
                _showSubtitlesSelectionWidget();
              }),
            _buildDivider(betterPlayerControlsConfiguration.enableQualities),
            if (betterPlayerControlsConfiguration.enableQualities)
              _buildMoreOptionsListRow(
                betterPlayerControlsConfiguration.qualitiesIcon,
                translations.overflowMenuQuality,
                () {
                  Navigator.of(context).pop();
                  _showQualitiesSelectionWidget();
                },
                selectedValue: betterPlayerController!.betterPlayerAsmsTrack
                    ?.qualityString(
                  betterPlayerController!.translations,
                ),
              ),
            _buildDivider(betterPlayerControlsConfiguration.enableAudioTracks),
            if (betterPlayerControlsConfiguration.enableAudioTracks)
              _buildMoreOptionsListRow(
                  betterPlayerControlsConfiguration.audioTracksIcon,
                  translations.overflowMenuAudioTracks, () {
                Navigator.of(context).pop();
                _showAudioTracksSelectionWidget();
              }),
            if (betterPlayerControlsConfiguration
                .overflowMenuCustomItems.isNotEmpty)
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
      ),
    );
  }

  Widget _buildMoreOptionsListRow(
    IconData icon,
    String name,
    void Function() onTap, {
    String? selectedValue,
  }) {
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
            const Expanded(child: const SizedBox()),
            if (selectedValue != null)
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

  void _showSpeedChooserWidget() {
    _showModalBottomSheet([
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.8),
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
              child: Icon(Icons.close),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
      // _buildSpeedRow(0.25),
      // _buildDivider(true),
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
    Color color = Colors.grey,
    double? height,
  }) {
    return Visibility(
      visible: visibilty,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
        child: Divider(
          color: color,
          height: height,
          indent: indent,
          endIndent: endIndent,
          thickness: 1,
        ),
      ),
    );
  }

  Widget _buildSpeedRow(double value) {
    final bool isSelected =
        betterPlayerController!.videoPlayerController!.value.speed == value;
    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        Navigator.of(context).pop();
        betterPlayerController!.setSpeed(value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            SizedBox(width: 8),
            Text(
              "$value x",
              style: _getOverflowMenuElementTextStyle(isSelected),
            ),
            Spacer(),
            Visibility(
                visible: isSelected,
                child: Icon(
                  Icons.check_outlined,
                  color: betterPlayerControlsConfiguration
                      .overflowModalSelectedIconColor,
                )),
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

        if (latestValue.isPlaying &&
            latestValue.isBuffering &&
            difference.inMilliseconds < _bufferingInterval) {
          return true;
        }
      }
    }
    return false;
  }

  void _showSubtitlesSelectionWidget() {
    final subtitles =
        List.of(betterPlayerController!.betterPlayerSubtitlesSourceList);
    final noneSubtitlesElementExists = subtitles.firstWhereOrNull(
            (source) => source.type == BetterPlayerSubtitlesSourceType.none) !=
        null;
    if (!noneSubtitlesElementExists) {
      subtitles.add(BetterPlayerSubtitlesSource(
          type: BetterPlayerSubtitlesSourceType.none));
    }

    _showModalBottomSheet(
        subtitles.map((source) => _buildSubtitlesSourceRow(source)).toList());
  }

  Widget _buildSubtitlesSourceRow(BetterPlayerSubtitlesSource subtitlesSource) {
    final selectedSourceType =
        betterPlayerController!.betterPlayerSubtitlesSource;
    final bool isSelected = (subtitlesSource == selectedSourceType) ||
        (subtitlesSource.type == BetterPlayerSubtitlesSourceType.none &&
            subtitlesSource.type == selectedSourceType!.type);

    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        Navigator.of(context).pop();
        betterPlayerController!.setupSubtitleSource(subtitlesSource);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            SizedBox(width: isSelected ? 8 : 16),
            Visibility(
                visible: isSelected,
                child: Icon(
                  Icons.check_outlined,
                  color: betterPlayerControlsConfiguration
                      .overflowModalSelectedIconColor,
                )),
            const SizedBox(width: 16),
            Text(
              subtitlesSource.type == BetterPlayerSubtitlesSourceType.none
                  ? betterPlayerController!.translations.generalNone
                  : subtitlesSource.name ??
                      betterPlayerController!.translations.generalDefault,
              style: _getOverflowMenuElementTextStyle(isSelected),
            ),
          ],
        ),
      ),
    );
  }

  ///Build both track and resolution selection
  ///Track selection is used for HLS / DASH videos
  ///Resolution selection is used for normal videos
  void _showQualitiesSelectionWidget() {
    final orientation = MediaQuery.of(context).orientation;
    // HLS / DASH
    final List<String> asmsTrackNames =
        betterPlayerController!.betterPlayerDataSource!.asmsTrackNames ?? [];
    final List<BetterPlayerAsmsTrack> asmsTracks =
        betterPlayerController!.betterPlayerAsmsTracks;

    final List<Widget> children = [];
    children.add(Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 0.8,
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
            child: Icon(Icons.close),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    ));
    final autoTrack = _buildTrackRow(
      BetterPlayerAsmsTrack.defaultTrack(),
      betterPlayerController!.translations.qualityAuto,
    );

    if (orientation == Orientation.landscape) {
      children.add(_buildDivider(
        true,
        height: 24,
        indent: 24,
        endIndent: 16,
        color: Colors.grey.withOpacity(0.3),
      ));
    }

    if (autoTrack != null) {
      children.add(autoTrack);
      if (orientation == Orientation.portrait) {
        children.add(_buildDivider(true));
      }
    }
    for (var index = 0; index < asmsTracks.length; index++) {
      final track = asmsTracks[index];
      String? preferredName;
      if (track.height == 0 && track.width == 0 && track.bitrate == 0) {
        preferredName = betterPlayerController!.translations.qualityAuto;
      } else {
        preferredName =
            asmsTrackNames.length > index ? asmsTrackNames[index] : null;
      }

      var data = _buildTrackRow(asmsTracks[index], preferredName);

      if (data != null) {
        children.add(data);
        bool showDivider = false;
        if (orientation == Orientation.portrait &&
            index != (asmsTracks.length - 1)) {
          showDivider = true;
        }
        children.add(_buildDivider(showDivider));
      }
    }

    // normal videos
    final resolutions =
        betterPlayerController!.betterPlayerDataSource!.resolutions;
    resolutions?.forEach((String key, value) {
      var data = _buildResolutionSelectionRow(key, value);
      if (data != null) children.add(data);
    });

    if (children.isEmpty) {
      var data = _buildTrackRow(BetterPlayerAsmsTrack.defaultTrack(),
          betterPlayerController!.translations.qualityAuto);
      if (data != null)
        children.add(
          data,
        );
    }

    _showModalBottomSheet(children);
  }

  Widget? _buildTrackRow(BetterPlayerAsmsTrack track, String? preferredName) {
    final orientation = MediaQuery.of(context).orientation;
    final int width = track.width ?? 0;
    final int height = track.height ?? 0;
    final int bitrate = track.bitrate ?? 0;
    final String mimeType = (track.mimeType ?? '').replaceAll('video/', '');
    String trackName = preferredName ??
        "${width}x$height ${BetterPlayerUtils.formatBitrate(bitrate)} $mimeType";
    String? trackDesc;
    // if (height == 360) {
    //   trackName = betterPlayerController!.translations.hdQuality!;
    //   trackDesc = betterPlayerController!.translations.hdQualityDesc!;
    // } else if (height == 180) {
    //   trackName = betterPlayerController!.translations.lowQuality!;
    //   trackDesc = betterPlayerController!.translations.lowQualityDesc!;
    // } else if (height == 720) {
    //   trackName = betterPlayerController!.translations.fullHdQuality!;
    //   trackDesc = betterPlayerController!.translations.fullHdQualityDesc!;
    // } else
    if (track.id == '') {
      trackName = preferredName!;
      trackDesc = betterPlayerController!.translations.autoQualityDesc!;
    } else {
      if (height == 1080) {
        trackName = betterPlayerController!.translations.fullHdQuality!;
        trackDesc = betterPlayerController!.translations.fullHdQualityDesc!;
      } else if (height == 720) {
        trackName = betterPlayerController!.translations.hdQuality!;
        trackDesc = betterPlayerController!.translations.hdQualityDesc!;
      } else if (height == 180) {
        trackName = betterPlayerController!.translations.lowQuality!;
        trackDesc = betterPlayerController!.translations.lowQualityDesc!;
      } else {
        trackName = '$height';
        trackDesc = (betterPlayerController!.translations.upToDesc).toString() +
            " " +
            '$height' +
            "p";
      }
    }

    final selectedTrack = betterPlayerController!.betterPlayerAsmsTrack;
    final bool isSelected = selectedTrack != null && selectedTrack == track;

    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        Navigator.of(context).pop();
        betterPlayerController!.setTrack(track);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            if (orientation == Orientation.landscape)
              Visibility(
                visible: isSelected,
                child: Icon(
                  Icons.check_outlined,
                  color: Colors.red,
                ),
              ),
            if (orientation == Orientation.landscape && !isSelected)
              const SizedBox(width: 24),
            const SizedBox(width: 8),
            Text(
              trackName,
              style: _getOverflowMenuElementTextStyle(true),
            ),
            const SizedBox(width: 8),
            Text(
              '$trackDesc',
              style: _getOverflowMenuElementTextStyle(false).copyWith(
                fontSize: 12,
              ),
            ),
            const Spacer(),
            if (orientation == Orientation.portrait)
              Visibility(
                  visible: isSelected,
                  child: Icon(
                    Icons.check_outlined,
                    color: betterPlayerControlsConfiguration
                        .overflowModalSelectedIconColor,
                  )),
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

    final bool isSelected =
        url == betterPlayerController!.betterPlayerDataSource!.url;
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
                child: Icon(
                  Icons.check_outlined,
                  color:
                      betterPlayerControlsConfiguration.overflowModalTextColor,
                )),
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
    final List<BetterPlayerAsmsAudioTrack>? asmsTracks =
        betterPlayerController!.betterPlayerAsmsAudioTracks;
    final List<Widget> children = [];
    final BetterPlayerAsmsAudioTrack? selectedAsmsAudioTrack =
        betterPlayerController!.betterPlayerAsmsAudioTrack;
    if (asmsTracks != null) {
      for (var index = 0; index < asmsTracks.length; index++) {
        final bool isSelected = selectedAsmsAudioTrack != null &&
            selectedAsmsAudioTrack == asmsTracks[index];
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

  Widget _buildAudioTrackRow(
      BetterPlayerAsmsAudioTrack audioTrack, bool isSelected) {
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
                child: Icon(
                  Icons.check_outlined,
                  color:
                      betterPlayerControlsConfiguration.overflowModalTextColor,
                )),
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
      color: isSelected
          ? betterPlayerControlsConfiguration.overflowModalTextColor
          : betterPlayerControlsConfiguration.overflowModalTextColor
              .withOpacity(0.7),
    );
  }

  void _showModalBottomSheet(List<Widget> children) {
    _showMaterialBottomSheet(children);
  }

  void _showCupertinoModalBottomSheet(List<Widget> children) {
    showCupertinoModalPopup<void>(
      barrierColor: Colors.transparent,
      context: context,
      useRootNavigator:
          betterPlayerController?.betterPlayerConfiguration.useRootNavigator ??
              false,
      builder: (context) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: betterPlayerControlsConfiguration.overflowModalColor,
                /*shape: RoundedRectangleBorder(side: Bor,borderRadius: 24,)*/
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    topRight: Radius.circular(10.0)),
              ),
              child: Column(
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMaterialBottomSheet(List<Widget> children) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final backgroundColor = orientation == Orientation.landscape
        ? Colors.black
        : betterPlayerControlsConfiguration.overflowModalColor;
    showModalBottomSheet<void>(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      context: context,
      useRootNavigator:
          betterPlayerController?.betterPlayerConfiguration.useRootNavigator ??
              false,
      builder: (context) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              height: size.height,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: size.height * 0.06,
                  ),
                  ...children
                ],
              ),
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
    setState(() {
      if (notVisible) {
        betterPlayerController?.postEvent(
            BetterPlayerEvent(BetterPlayerEventType.controlsHiddenStart));
      }
      controlsNotVisible = notVisible;
    });
  }
}

//
