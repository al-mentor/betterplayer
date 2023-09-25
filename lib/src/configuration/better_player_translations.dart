///Class used to hold translations for all features within Better Player
class BetterPlayerTranslations {
  final String languageCode;
  final String generalDefaultError;
  final String generalNone;
  final String generalDefault;
  final String generalRetry;
  final String playlistLoadingNextVideo;
  final String controlsLive;
  final String controlsNextVideoIn;
  final String overflowMenuPlaybackSpeed;
  final String overflowMenuSubtitles;
  final String overflowMenuQuality;
  final String overflowMenuAudioTracks;
  final String qualityAuto;
  final String properites;
  final String speed;
  final String? hdQuality;
  final String? lowQuality;
  final String? fullHdQuality;
  final String? autoQualityDesc;
  final String? fullHdQualityDesc;
  final String? hdQualityDesc;
  final String? upToDesc;
  final String? lowQualityDesc;

  BetterPlayerTranslations({
    this.upToDesc = "Up To",
    this.languageCode = "en",
    this.generalDefaultError = "Video can't be played",
    this.generalNone = "None",
    this.generalDefault = "Default",
    this.generalRetry = "Retry",
    this.playlistLoadingNextVideo = "Loading next video",
    this.controlsLive = "LIVE",
    this.controlsNextVideoIn = "Next video in",
    this.overflowMenuPlaybackSpeed = "Playback speed",
    this.overflowMenuSubtitles = "Subtitles",
    this.overflowMenuQuality = "Quality",
    this.overflowMenuAudioTracks = "Audio",
    this.qualityAuto = "Auto",
    this.properites = "Properties",
    this.speed = "Speed",
    this.hdQuality = "HD",
    this.lowQuality = "Low Quality",
    this.fullHdQuality = 'Full HD',
    this.autoQualityDesc = 'To get the best possible experience',
    this.lowQualityDesc = 'data saver',
    this.fullHdQualityDesc = 'up to 1080p',
    this.hdQualityDesc = 'up to 720p',
  });

  factory BetterPlayerTranslations.polish() => BetterPlayerTranslations(
    languageCode: "pl",
    generalDefaultError: "Video nie może zostać odtworzone",
    generalNone: "Brak",
    generalDefault: "Domyślne",
    generalRetry: "Spróbuj ponownie",
    playlistLoadingNextVideo: "Ładowanie następnego filmu",
    controlsNextVideoIn: "Następne video za",
    overflowMenuPlaybackSpeed: "Szybkość odtwarzania",
    overflowMenuSubtitles: "Napisy",
    overflowMenuQuality: "Jakość",
    overflowMenuAudioTracks: "Dźwięk",
    qualityAuto: "Automatycznie",
  );

  factory BetterPlayerTranslations.chinese() => BetterPlayerTranslations(
    languageCode: "zh",
    generalDefaultError: "无法播放视频",
    generalNone: "没有",
    generalDefault: "默认",
    generalRetry: "重試",
    playlistLoadingNextVideo: "正在加载下一个视频",
    controlsLive: "直播",
    controlsNextVideoIn: "下一部影片",
    overflowMenuPlaybackSpeed: "播放速度",
    overflowMenuSubtitles: "字幕",
    overflowMenuQuality: "质量",
    overflowMenuAudioTracks: "音訊",
    qualityAuto: "汽車",
  );

  factory BetterPlayerTranslations.hindi() => BetterPlayerTranslations(
    languageCode: "hi",
    generalDefaultError: "वीडियो नहीं चलाया जा सकता",
    generalNone: "कोई नहीं",
    generalDefault: "चूक",
    generalRetry: "पुनः प्रयास करें",
    playlistLoadingNextVideo: "अगला वीडियो लोड हो रहा है",
    controlsLive: "लाइव",
    controlsNextVideoIn: "में अगला वीडियो",
    overflowMenuPlaybackSpeed: "प्लेबैक की गति",
    overflowMenuSubtitles: "उपशीर्षक",
    overflowMenuQuality: "गुणवत्ता",
    overflowMenuAudioTracks: "ऑडियो",
    qualityAuto: "ऑटो",
  );

  factory BetterPlayerTranslations.arabic() => BetterPlayerTranslations(
      languageCode: "ar",
      generalDefaultError: "لا يمكن تشغيل الفيديو",
      generalNone: "لا يوجد",
      generalDefault: "الاساسي",
      generalRetry: "اعادة المحاوله",
      playlistLoadingNextVideo: "تحميل الفيديو التالي",
      controlsLive: "مباشر",
      controlsNextVideoIn: "الفيديو التالي في",
      overflowMenuPlaybackSpeed: "سرعة التشغيل",
      overflowMenuSubtitles: "الترجمة",
      overflowMenuQuality: "الجودة",
      overflowMenuAudioTracks: "الصوت",
      qualityAuto: "تلقائي",
      properites: "الخصائص",
      speed: "السرعه",
      fullHdQuality: "Full HD",
      hdQuality: "HD",
      lowQuality: "جودة منخفضة",
      autoQualityDesc: 'للحصول على افضل تجربة ممكنة',
      lowQualityDesc: 'موفر البيانات',
      fullHdQualityDesc: 'تصل الي 1080p',
      hdQualityDesc: 'تصل الي 720p',
      upToDesc: 'تصل الي'
  );

  factory BetterPlayerTranslations.turkish() => BetterPlayerTranslations(
      languageCode: "tr",
      generalDefaultError: "Video oynatılamıyor",
      generalNone: "Hiçbiri",
      generalDefault: "Varsayılan",
      generalRetry: "Tekrar Dene",
      playlistLoadingNextVideo: "Sonraki video yükleniyor",
      controlsLive: "CANLI",
      controlsNextVideoIn: "Sonraki video oynatılmadan",
      overflowMenuPlaybackSpeed: "Oynatma hızı",
      overflowMenuSubtitles: "Altyazı",
      overflowMenuQuality: "Kalite",
      overflowMenuAudioTracks: "Ses",
      qualityAuto: "Otomatik");

  factory BetterPlayerTranslations.vietnamese() => BetterPlayerTranslations(
    languageCode: "vi",
    generalDefaultError: "Video không thể phát bây giờ",
    generalNone: "Không có",
    generalDefault: "Mặc định",
    generalRetry: "Thử lại ngay",
    controlsLive: "Trực tiếp",
    playlistLoadingNextVideo: "Đang tải video tiếp theo",
    controlsNextVideoIn: "Video tiếp theo",
    overflowMenuPlaybackSpeed: "Tốc độ phát",
    overflowMenuSubtitles: "Phụ đề",
    overflowMenuQuality: "Chất lượng",
    overflowMenuAudioTracks: "Âm thanh",
    qualityAuto: "Tự động",
  );

  factory BetterPlayerTranslations.spanish() => BetterPlayerTranslations(
    languageCode: "es",
    generalDefaultError: "No se puede reproducir el video",
    generalNone: "Ninguno",
    generalDefault: "Por defecto",
    generalRetry: "Reintentar",
    controlsLive: "EN DIRECTO",
    playlistLoadingNextVideo: "Cargando siguiente video",
    controlsNextVideoIn: "Siguiente video en",
    overflowMenuPlaybackSpeed: "Velocidad",
    overflowMenuSubtitles: "Subtítulos",
    overflowMenuQuality: "Calidad",
    qualityAuto: "Automática",
  );
}

