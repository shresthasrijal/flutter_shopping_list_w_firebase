import 'package:flutter/material.dart';
import 'package:projj10_shopping_list_w_backend/data/categories.dart';
import 'package:projj10_shopping_list_w_backend/models/grocery_item.dart';
import 'package:projj10_shopping_list_w_backend/widgets/new_item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
      'insert_ur_firebase_url',
      'shopping-list.json',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode >= 400) {
        setState(() {
          _error =
              'Error ${response.statusCode.toString()}: to fetch data. Please try again later';
        });
      }

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];

      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;
        loadedItems.add(GroceryItem(
          id: item.key,
          category: category,
          name: item.value['name'],
          quantity: item.value['quantity'],
        ));
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong. Please try again later!';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.push<GroceryItem>(
      context,
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    } else {
      setState(() {
        _groceryItems.add(newItem);
      });
    }
  }

  void _removeItem(GroceryItem item, int index) async {
    setState(() {
      _groceryItems.removeAt(index);
    });

    final url = Uri.https(
      'insert_ur_firebase_url',
      'shopping-list/${item.id}.json',
    );
    final response = await http.delete(url);

    if (!mounted) {
      return;
    }

    if (response.statusCode >= 400) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Error ${response.statusCode}'),
          content: const Text('Could not delete item.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Okay'),
            ),
          ],
        ),
      );

      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  SnackBar buildSnackBar(
      BuildContext context, GroceryItem tempItem, int index) {
    return SnackBar(
      content: Text('${tempItem.name} dismissed'),
      duration: const Duration(seconds: 6),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () async {
          final url = Uri.https(
            'insert_ur_firebase_url',
            'shopping-list.json',
          );
          final response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode(
              {
                'name': tempItem.name,
                'quantity': tempItem.quantity,
                'category': tempItem.category.title,
              },
            ),
          );
          final Map<String, dynamic> resData = json.decode(response.body);
          setState(() {
            _groceryItems.insert(
              index,
              GroceryItem(
                id: resData['name'],
                category: tempItem.category,
                name: tempItem.name,
                quantity: tempItem.quantity,
              ),
            );
          });
        },
      ),
    );
  }

  void _setDone(int index, bool isChecked) {
    setState(() {
      _groceryItems[index].done = isChecked;
    });
  }

  @override
  Widget build(context) {
    Widget content = Center(
      child: Text(
        'Empty list, add some items!',
        style: Theme.of(context)
            .textTheme
            .headlineSmall!
            .copyWith(color: Colors.white),
      ),
    );

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      content = Center(
        child: Text(
          _error!,
          style: Theme.of(context)
              .textTheme
              .headlineSmall!
              .copyWith(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: _groceryItems.isEmpty
          ? content
          : content = ReorderableListView.builder(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _groceryItems.removeAt(oldIndex);
                  _groceryItems.insert(newIndex, item);
                });
              },
              itemCount: _groceryItems.length,
              buildDefaultDragHandles: true,
              itemBuilder: (context, index) {
                final groceryItem = _groceryItems[index];
                return Dismissible(
                  key: ValueKey(groceryItem.id),
                  onDismissed: (direction) {
                    final tempItem = _groceryItems[index];
                    _removeItem(_groceryItems[index], index);
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    if (!_groceryItems.contains(tempItem)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        buildSnackBar(context, tempItem, index),
                      );
                    }
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Theme.of(context).colorScheme.onError,
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Checkbox(
                          value: _groceryItems[index].done,
                          onChanged: (isChecked) =>
                              _setDone(index, isChecked ?? false),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: _groceryItems[index].category.title,
                          child: Icon(
                            Icons.square,
                            color: _groceryItems[index].category.color,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      _groceryItems[index].name,
                      style: _groceryItems[index].done
                          ? Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(decoration: TextDecoration.lineThrough)
                          : Theme.of(context).textTheme.bodyMedium,
                    ),
                    trailing: Text(
                      _groceryItems[index].quantity.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    subtitle: const Divider(
                      height: 1.0, // Set the thickness of the line
                      color: Colors.white, // Set the color of the line
                    ),
                  ),
                );
              },
            ),
    );
  }
}
