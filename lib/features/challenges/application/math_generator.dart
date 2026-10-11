import 'dart:math';

import '../domain/challenge_type.dart';

class MathQuestion {
  const MathQuestion(this.text, this.answer);

  final String text;
  final int answer;
}

class MathGenerator {
  MathGenerator([Random? random]) : _r = random ?? Random();

  final Random _r;

  int _between(int lo, int hi) => lo + _r.nextInt(hi - lo + 1);

  MathQuestion next(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        // Addition / subtraction, small numbers.
        return _addSub(2, 20);
      case Difficulty.medium:
        return _r.nextBool() ? _addSub(20, 99) : _mul(2, 9, 2, 9);
      case Difficulty.hard:
        final k = _r.nextInt(3);
        if (k == 0) return _addSub(100, 999);
        if (k == 1) return _mul(11, 25, 3, 9);
        return _mul(12, 19, 12, 19);
    }
  }

  MathQuestion _addSub(int lo, int hi) {
    final a = _between(lo, hi);
    final b = _between(lo, hi);
    if (_r.nextBool()) return MathQuestion('$a + $b', a + b);
    final big = max(a, b), small = min(a, b);
    return MathQuestion('$big − $small', big - small);
  }

  MathQuestion _mul(int aLo, int aHi, int bLo, int bHi) {
    final a = _between(aLo, aHi);
    final b = _between(bLo, bHi);
    return MathQuestion('$a × $b', a * b);
  }
}
