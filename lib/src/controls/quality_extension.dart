import 'package:better_player/better_player.dart';

extension QualityExtension on BetterPlayerAsmsTrack{
  String? qualityString(BetterPlayerTranslations translations){
    if (width == 480) {
      return translations.hdQuality;
    } else if (width == 320) {
      return  translations.lowQuality;
    } else if (width == 1280) {
      return translations.fullHdQuality;
    } else if(id == ''){
      return translations.qualityAuto;
    } else {
      return null;
    }
  }



}