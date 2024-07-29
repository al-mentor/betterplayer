
// ignore: prefer-match-file-name, this has a different name because of the deprecation.
import 'package:better_player/src/core/subtitle_wrapper/subtitle_wrapper.dart';

class SubTitleWrapper extends SubtitleWrapper {
  const SubTitleWrapper({
    required super.videoChild,
    required super.subtitleController,
    required super.videoPlayerController,
    super.key,
    super.subtitleStyle,
    super.backgroundColor,
  });
}
