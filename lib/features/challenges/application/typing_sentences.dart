import 'dart:math';

const _en = [
  'Rise and shine, today is going to be great.',
  'Every morning is a new chance to begin again.',
  'Discipline is choosing what you want most over what you want now.',
  'The early riser conquers the day.',
  'Get up, get moving, and make it count.',
  'Small steps every morning build a big life.',
];

const _uz = [
  "Tong otdi, yangi kun yangi imkoniyatlar demak.",
  "Erta turgan kishining rizqi butun bo'ladi.",
  "Bugungi ishni ertaga qoldirma.",
  "Har bir tong yangi boshlanish uchun imkoniyatdir.",
  "Intizom orzularni haqiqatga aylantiradi.",
  "O'rningdan tur va kunni mazmunli o'tkaz.",
];

String randomSentence(String language, [Random? random]) {
  final list = language == 'uz' ? _uz : _en;
  return list[(random ?? Random()).nextInt(list.length)];
}

/// Makes the comparison forgiving about invisible differences only:
/// surrounding/duplicate whitespace, case and the many apostrophe glyphs
/// Uzbek keyboards produce (' ʻ ʼ ’ ` ‘).
String normalizeTyped(String s) => s
    .replaceAll(RegExp("[ʻʼ’‘`´]"), "'")
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim()
    .toLowerCase();

bool sentenceMatches(String typed, String target) =>
    normalizeTyped(typed) == normalizeTyped(target);
