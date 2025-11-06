// lib/widgets/product_list.dart
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductList extends StatelessWidget {
  final ProductService _service = ProductService();

  ProductList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: _service.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return const Center(child: Text('No products found'));
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ListTile(
              title: Text(product.name),
              subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _editProductDialog(context, product);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _service.deleteProduct(product.id),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _editProductDialog(BuildContext context, Product product) {
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(text: product.price.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final updated = Product(
                id: product.id,
                name: nameController.text,
                price: double.tryParse(priceController.text) ?? 0,
              );
              _service.updateProduct(updated);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
