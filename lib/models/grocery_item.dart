import 'package:projj10_shopping_list_w_backend/models/category.dart';

class GroceryItem{
  GroceryItem({
    required this.id,
    required this.category,
    required this.name,
    required this.quantity,
    this.done = false,
  });

  final String id;
  final String name;
  final Category category;
  final int quantity;
  bool done;
}