import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:user_input/data/categories.dart';
//import 'package:user_input/data/dummy_item.dart';
import 'package:user_input/models/grocery_item.dart';
import 'package:user_input/widgets/new_item.dart';
import 'package:http/http.dart ' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> groceryItems = [];
  var _isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  void _loadItem() async {
    final url = Uri.https(
        'flutter-http-94953-default-rtdb.firebaseio.com', 'shopping-list.json');
    final response = await http.get(url);

    if (response.statusCode >= 400) {
      setState(() {
        error = 'Falied to fetch data. Please try again later.';
      });
    }
    if (response.body == 'null') {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> _loadedItems = [];

    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;

      _loadedItems.add(
        GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category),
      );
    }
    setState(() {
      groceryItems = _loadedItems;
      _isLoading = false;
    });
  }

  void _additem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    _loadItem();
    if (newItem == null) {
      return;
    }
    setState(() {
      groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = groceryItems.indexOf(item);

    setState(() {
      groceryItems.remove(item);
    });

    final url = Uri.https('flutter-http-94953-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No Item added Yet...'));

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(groceryItems[index]);
          },
          key: ValueKey(groceryItems[index].id),
          child: ListTile(
            title: Text(groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: groceryItems[index].category.color,
            ),
            trailing: Text(groceryItems[index].quantity.toString()),
          ),
        ),
      );
    }

    if (error != null) {
      content = Center(
        child: Text(error!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _additem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
