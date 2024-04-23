// import 'package:auto_route/auto_route.dart';
import 'package:better_player/src/core/video_speed_landscape_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class SpeedControllerBottomSheet extends StatefulWidget {
  const SpeedControllerBottomSheet({
    required this.onSpeedChanged,
    required this.speedList,
    required this.videoSpeedIndicator,
  });
  final void Function(int) onSpeedChanged;
  final List<VideoSpeedModel> speedList;
  final double videoSpeedIndicator;

  @override
  State<SpeedControllerBottomSheet> createState() => _SpeedControllerBottomSheetState();
}

class _SpeedControllerBottomSheetState extends State<SpeedControllerBottomSheet> {
  late double videoSpeedIndicator;

  @override
  void initState() {
    super.initState();
    videoSpeedIndicator = widget.videoSpeedIndicator;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 16.h),
          _buildSpeedProgress(),
          SizedBox(height: 10.h),
          _buildSpeedHorizontailList(),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCloseSpeedIcon() {
    return InkWell(
      onTap: () {
        _closeSpeedModalSheet(context);
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Icon(Icons.close),
      ),
    );
  }

  void _closeSpeedModalSheet(BuildContext context) {
    Navigator.of(context).pop();
  }

  Widget _buildSpeedProgress() {
    return Container(
      width: context.mediaQuerySize.width,
      padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 8),
      child: Row(
        children: [
          const Spacer(),
          Expanded(
            flex: 12,
            child: _progressBar(),
          ),
          Expanded(
            child: _buildCloseSpeedIcon(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedHorizontailList() {
    final speedList = widget.speedList;
    return Container(
      constraints: BoxConstraints(
        maxWidth: context.mediaQuerySize.width,
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 55),
      //height: 50.h,
      width: context.mediaQuerySize.width,
      child: Row(
        children: [
          const Spacer(),
          Expanded(
            flex: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final speedItem in speedList)
                  InkWell(
                    onTap: () async {
                      final index = speedList.indexOf(speedItem);
                      // setState(() async {
                      videoSpeedIndicator = index.toDouble();
                      widget.onSpeedChanged(index);
                      _closeSpeedModalSheet(context);
                      // });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(
                        child: Text(speedItem.speedText),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _progressBar() {
    return Slider(
      label: widget.speedList[videoSpeedIndicator.toInt()].speedText,
      value: videoSpeedIndicator,
      activeColor: Colors.white,
      inactiveColor: Colors.white,
      allowedInteraction: SliderInteraction.tapAndSlide,
      onChanged: (value) async {
        setState(
          () {
            videoSpeedIndicator = value;
            widget.onSpeedChanged(videoSpeedIndicator.toInt());
          },
        );
      },
      min: 0,
      max: 5,
      divisions: 5,
    );
  }
}
