import 'dart:math' as math;

import 'package:flutter/material.dart';

enum VoiceZone { none, revise, cancel }

/// All coordinates refer to the recording viewport (the card for Quick Ask).
/// The very same paths paint the wings and resolve a drag.
class VoiceGestureGeometry {
  VoiceGestureGeometry(this.size);
  final Size size;
  double get unit => math.min(size.width, math.min(size.height * .68, 480));
  double get crest =>
      size.height - math.min(size.height * .145, size.width * .31);
  double labelX(bool left) => size.width * (left ? .195 : .805);
  double get labelY => crest - unit * .095;

  Path wing(bool left) {
    double x(double fraction) => size.width * (left ? fraction : 1 - fraction);
    double y(double shift) => crest + shift * unit;
    return Path()
      ..moveTo(x(0), y(-.119))
      ..cubicTo(x(.11), y(-.16), x(.29), y(-.195), x(.374), y(-.196))
      ..cubicTo(x(.424), y(-.2), x(.46), y(-.165), x(.461), y(-.119))
      ..cubicTo(x(.464), y(-.078), x(.44), y(-.051), x(.399), y(-.044))
      ..cubicTo(x(.25), y(-.028), x(.105), y(.015), x(0), y(.054))
      ..close();
  }

  Path get base {
    final w = size.width;
    return Path()
      ..moveTo(0, crest + .096 * unit)
      ..cubicTo(
        w * .29,
        crest - .032 * unit,
        w * .71,
        crest - .032 * unit,
        w,
        crest + .096 * unit,
      )
      ..lineTo(w, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  VoiceZone hit(Offset point) {
    if (wing(true).contains(point)) return VoiceZone.cancel;
    if (wing(false).contains(point)) return VoiceZone.revise;
    return VoiceZone.none;
  }
}

VoiceZone voiceZoneAt(GlobalKey surface, Offset global) {
  final box = surface.currentContext?.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return VoiceZone.none;
  return VoiceGestureGeometry(box.size).hit(box.globalToLocal(global));
}
