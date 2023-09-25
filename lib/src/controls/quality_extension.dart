import 'package:better_player/better_player.dart';

extension QualityExtension on BetterPlayerAsmsTrack{
  String? qualityString(BetterPlayerTranslations translations){
    if (height == 720) {
      return translations.hdQuality;
    } else if (height == 180) {
      return  translations.lowQuality;
    } else if (height == 1080) {
      return translations.fullHdQuality;
    } else if(id == ''){
      return translations.qualityAuto;
    } else {
      return height.toString()+"p";
    }
  }

//

}