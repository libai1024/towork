import 'package:flutter/material.dart';

/// Tier colors shared by the account badge and the package selector.
class MembershipStyle {
  const MembershipStyle(this.background, this.foreground);
  final Color background, foreground;

  static MembershipStyle of(BuildContext context, int tier) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return (dark
        ? const [
            MembershipStyle(Color(0xff373632), Color(0xffe5e1d6)),
            MembershipStyle(Color(0xff54462c), Color(0xfff1dda6)),
            MembershipStyle(Color(0xff623d29), Color(0xffffdab9)),
            MembershipStyle(Color(0xff51412c), Color(0xffffe0a1)),
          ]
        : const [
            MembershipStyle(Color(0xffe9e7df), Color(0xff55544c)),
            MembershipStyle(Color(0xffeee1bb), Color(0xff604824)),
            MembershipStyle(Color(0xfff0d5bd), Color(0xff794223)),
            MembershipStyle(Color(0xff33271f), Color(0xfff4d8a2)),
          ])[tier];
  }
}
