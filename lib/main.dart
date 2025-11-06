import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventory Management App',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  final CollectionReference _products =
      FirebaseFirestore.instance.collection('products');

  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;

  // CREATE or UPDATE
  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
      _nameController.text = documentSnapshot['name'];
      _priceController.text = documentSnapshot['price'].toString();
    }

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                child: Text(action == 'create' ? 'Create' : 'Update'),
                onPressed: () async {
                  final name = _nameController.text.trim();
                  final double? price = double.tryParse(_priceController.text);
                  if (name.isNotEmpty && price != null) {
                    if (action == 'create') {
                      await _products.add({'name': name, 'price': price});
                    } else {
                      await _products.doc(documentSnapshot!.id).update({
                        'name': name,
                        'price': price,
                      });
                    }
                    _nameController.clear();
                    _priceController.clear();
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // DELETE
  Future<void> _deleteProduct(String productId) async {
    await _products.doc(productId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product deleted successfully')),
    );
  }

  // FILTER
  void _applyPriceFilter() {
    setState(() {
      _minPrice = double.tryParse(_minPriceController.text);
      _maxPrice = double.tryParse(_maxPriceController.text);
    });
  }

  // RESET FILTER
  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _searchQuery = '';
      _minPrice = null;
      _maxPrice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore CRUD + Search + Dashboard'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by name...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.trim().toLowerCase());
              },
            ),
          ),

          // PRICE FILTER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Min Price',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Max Price',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _applyPriceFilter,
                  child: const Text('Filter'),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // PRODUCT LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _products.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];

                final filtered = docs.where((doc) {
                  final name = doc['name'].toString().toLowerCase();
                  final price = (doc['price'] as num).toDouble();

                  final matchesSearch = _searchQuery.isEmpty ||
                      name.contains(_searchQuery);
                  final matchesMin =
                      _minPrice == null || price >= _minPrice!;
                  final matchesMax =
                      _maxPrice == null || price <= _maxPrice!;

                  return matchesSearch && matchesMin && matchesMax;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: ListTile(
                        title: Text(doc['name']),
                        subtitle: Text(
                            '\$${(doc['price'] as num).toStringAsFixed(2)}'),
                        trailing: SizedBox(
                          width: 100,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _createOrUpdate(doc),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteProduct(doc.id),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // TWO FLOATING BUTTONS: ADD + DASHBOARD
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add',
            backgroundColor: Colors.blueAccent,
            onPressed: () => _createOrUpdate(),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'dashboard',
            backgroundColor: Colors.deepPurple,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DashboardPage()),
              );
            },
            child: const Icon(Icons.dashboard),
          ),
        ],
      ),
    );
  }
}

// ===========================
// DASHBOARD PAGE
// ===========================
class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  Stream<QuerySnapshot> getProductsStream() {
    return FirebaseFirestore.instance.collection('products').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Dashboard'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          final totalProducts = docs.length;
          double totalValue = 0;
          final outOfStock = <String>[];

          for (var doc in docs) {
            final name = doc['name'] ?? 'Unknown';
            final price = (doc['price'] ?? 0).toDouble();
            totalValue += price;

            if (price == 0) {
              outOfStock.add(name);
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.blue.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.inventory_2, color: Colors.blue),
                    title: const Text('Total Products'),
                    trailing: Text('$totalProducts'),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  color: Colors.green.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.attach_money, color: Colors.green),
                    title: const Text('Total Inventory Value'),
                    trailing: Text('\$${totalValue.toStringAsFixed(2)}'),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Out of Stock Items',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.redAccent,
                            ),
                          ),
                          const Divider(),
                          Expanded(
                            child: outOfStock.isEmpty
                                ? const Center(
                                    child: Text('All items in stock ✅'),
                                  )
                                : ListView.builder(
                                    itemCount: outOfStock.length,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        title: Text(outOfStock[index]),
                                        leading: const Icon(Icons.warning_amber,
                                            color: Colors.redAccent),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
