enum ChallengeType { math, shake, typing, qr, barcode, walk }

enum Difficulty { easy, medium, hard }

extension ChallengeTypeX on ChallengeType {
  bool get needsScan =>
      this == ChallengeType.qr || this == ChallengeType.barcode;
}
