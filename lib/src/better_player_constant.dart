

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class BetterPlayerConstant {
  static  Widget videoCloseIcon  = const SizedBox();

  static bool isRtl(BuildContext context) =>
      Localizations.localeOf(context).languageCode == "ar" ? true : false;
}

bool isRtl2() {
  String currentLocal = Intl.getCurrentLocale();
  if (currentLocal.contains('ar')) {
    return true;
  } else {
    return false;
  }
}
