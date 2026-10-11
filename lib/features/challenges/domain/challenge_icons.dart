import 'package:flutter/material.dart';

import 'challenge_type.dart';

IconData challengeIcon(ChallengeType t) => switch (t) {
  ChallengeType.math => Icons.calculate_outlined,
  ChallengeType.shake => Icons.vibration,
  ChallengeType.typing => Icons.keyboard_outlined,
  ChallengeType.qr => Icons.qr_code_scanner,
  ChallengeType.barcode => Icons.barcode_reader,
  ChallengeType.walk => Icons.directions_walk,
};
