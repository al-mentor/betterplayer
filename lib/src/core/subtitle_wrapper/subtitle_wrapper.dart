import 'package:better_player/src/core/subtitle_wrapper/subtitle_controller.dart';
import 'package:better_player/src/core/subtitle_wrapper/subtitle_text_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../better_player.dart';
import 'bloc/bloc.dart';
import 'data/data.dart';


class SubtitleWrapper extends StatelessWidget {
  const SubtitleWrapper({
    required this.videoChild,
    required this.subtitleController,
    required this.videoPlayerController,
    super.key,
    this.subtitleStyle = const SubtitleStyle(),
    this.backgroundColor,
  });
  final Widget videoChild;
  final SubtitleController subtitleController;
  final VideoPlayerController videoPlayerController;
  final SubtitleStyle subtitleStyle;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        videoChild,
        if (subtitleController.showSubtitles)
          Positioned(
            top: subtitleStyle.position.top,
            bottom: subtitleStyle.position.bottom,
            left: subtitleStyle.position.left,
            right: subtitleStyle.position.right,
            child: BlocProvider(
              create: (context) => SubtitleBloc(
                videoPlayerController: videoPlayerController,
                subtitleRepository: SubtitleDataRepository(
                  subtitleController: subtitleController,
                ),
                subtitleController: subtitleController,
              )..add(
                  InitSubtitles(
                    subtitleController: subtitleController,
                  ),
                ),
              child: SubtitleTextView(
                subtitleStyle: subtitleStyle,
                backgroundColor: backgroundColor,
              ),
            ),
          )
        else
          Container(),
      ],
    );
  }
}
