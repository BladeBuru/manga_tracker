import 'package:flutter/material.dart';

/// Rayon de bordure utilisé dans l'ensemble de l'application
class AppRadius {
  AppRadius._();

  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 10.0;
  static const double xl = 12.0;
  static const double xxl = 15.0;
  static const double xxxl = 16.0;
  static const double huge = 18.0;
  static const double jumbo = 20.0;

  static final BorderRadius circularXs = BorderRadius.circular(xs);
  static final BorderRadius circularSm = BorderRadius.circular(sm);
  static final BorderRadius circularMd = BorderRadius.circular(md);
  static final BorderRadius circularLg = BorderRadius.circular(lg);
  static final BorderRadius circularXl = BorderRadius.circular(xl);
  static final BorderRadius circularXxl = BorderRadius.circular(xxl);
  static final BorderRadius circularXxxl = BorderRadius.circular(xxxl);
  static final BorderRadius circularHuge = BorderRadius.circular(huge);
  static final BorderRadius circularJumbo = BorderRadius.circular(jumbo);

  static BorderRadius circular(double radius) => BorderRadius.circular(radius);
}

