import 'package:better_player/better_player.dart';

extension QualityExtension on BetterPlayerAsmsTrack {
  String? qualityString(BetterPlayerTranslations translations) {
    if (id == '') {
      if (height == 0) {
        return translations.qualityAuto;
      }
    }
    return "${height}p";
  }
}

class QualityValues {
  bool avalivle1080;
  bool avalivle720;
  bool avalivle540;
  bool avalivle360;
  bool avalivle270;
  bool avalivle180;

  QualityValues({
    this.avalivle1080 = false,
    this.avalivle720 = false,
    this.avalivle540 = false,
    this.avalivle360 = false,
    this.avalivle270 = false,
    this.avalivle180 = false,
  });
}
