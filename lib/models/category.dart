import 'package:flutter/material.dart';

class Category {
  const Category(this.title, this.color);

  final String title;
  final Color color;
}

enum Categories {
  vegetables,
  fruit,
  meat,
  dairy,
  carbs,
  sweets,
  spices,
  convenience,
  hygiene,
  other,
}
