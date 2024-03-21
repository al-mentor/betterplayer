// Flutter imports:
import 'package:flutter/material.dart';

class BetterPlayerMaterialClickableWidget extends StatelessWidget {
  final Widget child;
  final void Function() onTap;
  final double? raduis;
  const BetterPlayerMaterialClickableWidget({
    Key? key,
    required this.onTap,
    required this.child,
    this.raduis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      animationDuration: Duration(microseconds: 10),
      borderOnForeground: false,
      type: MaterialType.transparency,
      borderRadius: BorderRadius.circular(raduis ?? 60),
      clipBehavior: Clip.hardEdge,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: child,
      ),
    );
  }
}
