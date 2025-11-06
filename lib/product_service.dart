// lib/services/product_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');

  // Create
  Future<void> addProduct(Product product) {
    return _productsCollection.add(product.toMap());
  }

  // Read (stream for real-time updates)
  Stream<List<Product>> getProducts() {
    return _productsCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Update
  Future<void> updateProduct(Product product) {
    return _productsCollection.doc(product.id).update(product.toMap());
  }

  // Delete
  Future<void> deleteProduct(String id) {
    return _productsCollection.doc(id).delete();
  }
}
