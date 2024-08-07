import 'package:better_player/src/asms/better_player_asms_subtitle_segment.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'better_player_subtitles_source_type.dart';

///Representation of subtitles source. Used to define subtitles in Better
/// Player.
class BetterPlayerSubtitlesSource {
  ///Source type
  final BetterPlayerSubtitlesSourceType? type;

  ///Name of the subtitles, default value is "Default subtitles"
  final String? name;

  ///Url of the subtitles, used with file or network subtitles
  final List<String?>? urls;

  ///Content of subtitles, used when type is memory
  final String? content;

  ///Subtitles selected by default, without user interaction
  final bool? selectedByDefault;

  //Additional headers used in HTTP request. Works only for
  // [BetterPlayerSubtitlesSourceType.memory] source type.
  final Map<String, String>? headers;

  ///Is ASMS segmented source (more than 1 subtitle file). This shouldn't be
  ///configured manually.
  final bool? asmsIsSegmented;

  ///Max. time between segments in milliseconds. This shouldn't be configured
  /// manually.
  final int? asmsSegmentsTime;

  ///List of segments (start,end,url of the segment). This shouldn't be
  ///configured manually.
  final List<BetterPlayerAsmsSubtitleSegment>? asmsSegments;

  BetterPlayerSubtitlesSource({
    this.type,
    this.name,
    this.urls,
    this.content,
    this.selectedByDefault,
    this.headers,
    this.asmsIsSegmented,
    this.asmsSegmentsTime,
    this.asmsSegments,
  });

  // return name depend on language
  String? nameLanguage(BuildContext context) {
    var lang = Localizations.localeOf(context).languageCode;

    if (name == null) {
      return name;
    }

    if (lang.contains("en")) {
      if (name!.toLowerCase().contains("ar")) {
        return "Arabic";
      } else if (name!.toLowerCase().contains("en")) {
        return "English";
      } else if (name!.toLowerCase().contains("fr")) {
        return "French";
      } else {
        return "Default";
      }
    } else if (lang.contains("ar")) {
      if (name!.toLowerCase().contains("ar")) {
        return "العربيه";
      } else if (name!.toLowerCase().contains("en")) {
        return "الإنجليزية";
      } else if (name!.toLowerCase().contains("fr")) {
        return "الفرنسيه";
      } else {
        return "الافتراضي";
      }
    }
    return name;
  }

  ///Creates list with only one subtitles
  static List<BetterPlayerSubtitlesSource> single({
    BetterPlayerSubtitlesSourceType? type,
    String name = "None",
    String? url,
    String? content,
    bool? selectedByDefault,
    Map<String, String>? headers,
  }) =>
      [
        BetterPlayerSubtitlesSource(
          type: type,
          name: name,
          urls: [url],
          content: content,
          selectedByDefault: selectedByDefault,
          headers: headers,
        )
      ];
}
