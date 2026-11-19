import 'dart:math';

import 'package:characters/characters.dart';

class LocalProfile {
  const LocalProfile({
    required this.id,
    required this.nickname,
    required this.version,
    required this.createdAt,
  });
  final String id;
  final String nickname;
  final int version;
  final DateTime createdAt;
}

enum ProfileFailureCode { invalidName, conflict, storage }

class ProfileFailure implements Exception {
  const ProfileFailure(this.code);
  final ProfileFailureCode code;
  @override
  String toString() => 'ProfileFailure(${code.name})';
}

String normalizeNickname(String input) {
  final name = input.trim();
  if (name.isEmpty ||
      name.characters.length > 40 ||
      RegExp(r'[\x00-\x1f\x7f\u2028\u2029]').hasMatch(name)) {
    throw const ProfileFailure(ProfileFailureCode.invalidName);
  }
  return name;
}

String createLocalUserId() {
  final random = Random.secure();
  return 'local_${List.generate(24, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
}

abstract interface class LocalProfileStore {
  Future<LocalProfile> loadOrCreateProfile();
  Future<LocalProfile> renameProfile(
    String name, {
    required int expectedVersion,
  });
}
