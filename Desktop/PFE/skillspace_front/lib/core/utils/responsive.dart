import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  static double hPad(BuildContext context) => isMobile(context) ? 20 : 80;
}
