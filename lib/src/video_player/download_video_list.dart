import 'dart:convert';

class DownloadVideoList {
  List<Download>? downloadList;

  DownloadVideoList.fromJson(String jsonString) {
    downloadList = (json.decode(jsonString) as List)
        .map((data) => Download.fromJson(data))
        .toList();
  }

  DownloadVideoList.fromMapList(List<Map<String, dynamic>> mapList) {
    downloadList = mapList.map((map) => Download.fromJson(map)).toList();
  }
}

class Download {
  String? downloadState;
  String? downloadId;
  String? uri;
  String? downloadPercentage;

  Download({
    required this.downloadState,
    required this.downloadId,
    required this.uri,
    required this.downloadPercentage,
  });

  factory Download.fromJson(Map<String, dynamic> json) {
    return Download(
      downloadState: json['downloadState'].toString(),
      downloadId: json['downloadId'],
      uri: json['uri'],
      downloadPercentage: json['downloadPercentage'].toString(),
    );
  }
}