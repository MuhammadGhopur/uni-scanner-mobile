import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/purchase_order.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> uploadPurchaseOrders(List<PurchaseOrder> purchaseOrders) async {
    // Referensi ke koleksi 'purchase_orders'
    CollectionReference poCollection = _db.collection('purchase_orders');

    // Menghapus semua dokumen yang ada di koleksi sebelum mengunggah yang baru
    // Ini adalah langkah opsional, Anda bisa menyesuaikannya jika Anda ingin mempertahankan data yang sudah ada
    // await _clearCollection(poCollection);

    WriteBatch batch = _db.batch();
    int uploadedCount = 0;

    for (var po in purchaseOrders) {
      // Menambahkan setiap PurchaseOrder sebagai dokumen ke koleksi
      // Anda bisa menggunakan po.poNumber sebagai ID dokumen, atau biarkan Firestore membuatnya secara otomatis
      batch.set(poCollection.doc(), po.toMap());
      uploadedCount++;

      // Firebase batched writes memiliki batas 500 operasi per batch
      if (uploadedCount % 499 == 0) {
        await batch.commit();
        batch = _db.batch(); // Buat batch baru
        print('$uploadedCount documents uploaded in batch.');
      }
    }

    // Commit batch terakhir jika ada operasi yang tersisa
    if (uploadedCount % 499 != 0 || uploadedCount == 0) {
      await batch.commit();
      print('Final batch committed. Total $uploadedCount documents uploaded to Firestore.');
    }
  }

  Future<void> _clearCollection(CollectionReference collection) async {
    QuerySnapshot snapshot = await collection.get();
    for (DocumentSnapshot ds in snapshot.docs) {
      await ds.reference.delete();
    }
    print('Collection ${collection.id} cleared.');
  }

  // New method to get all PO numbers from Firestore
  Future<List<String>> getAllPoNumbers() async {
    try {
      QuerySnapshot snapshot = await _db.collection('purchase_orders').get();
      return snapshot.docs
          .map((doc) => PurchaseOrder.fromMap(doc.data() as Map<String, dynamic>).poNumber)
          .where((poNumber) => poNumber.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error getting all PO numbers: $e');
      return [];
    }
  }

  // New method to get a product by PO number
  // Sekarang akan mencari dokumen berdasarkan field 'po_number' dan mengembalikan Map yang berisi data dan ID dokumen.
  Future<Map<String, dynamic>?> getProductByPo(String poNumber) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('purchase_orders')
          .where('po_number', isEqualTo: poNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Mengembalikan data dokumen beserta ID-nya
        return {...snapshot.docs.first.data() as Map<String, dynamic>, 'id': snapshot.docs.first.id};
      }
      return null;
    } catch (e) {
      print('Error getting product by PO number: $e');
      return null;
    }
  }

  // New method to get filtered products with pagination
  Future<List<Map<String, dynamic>>> getFilteredProducts({
    String searchQuery = '',
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      Query query = _db.collection('purchase_orders');

      if (searchQuery.isNotEmpty) {
        // Firestore doesn't support full-text search directly.
        // For partial matches, you'd need a third-party service like Algolia or a more complex setup.
        // For exact match or prefix match, you'll need to query by range.
        query = query.orderBy('po_number').startAt([searchQuery]).endAt(['$searchQuery\uf8ff']);
      }

      // For simplicity with offset, we'll fetch and then skip in memory for now.
      // For large datasets, consider cursor-based pagination with startAfterDocument.
      QuerySnapshot snapshot = await query.get();

      List<Map<String, dynamic>> allDocs = snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();

      if (offset >= allDocs.length) {
        return [];
      }
      return allDocs.sublist(offset, (offset + limit).clamp(0, allDocs.length));

    } catch (e) {
      print('Error getting filtered products: $e');
      return [];
    }
  }

  // New method to get the total count of POs
  Future<int> getPoCount() async {
    try {
      QuerySnapshot snapshot = await _db.collection('purchase_orders').get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting PO count: $e');
      return 0;
    }
  }

  // New method to insert a product
  // Sekarang menggunakan add() untuk ID dokumen otomatis
  Future<void> insertProduct({
    required String poNumber,
    required String custId,
    required String sku,
  }) async {
    try {
      await _db.collection('purchase_orders').add({
        'po_number': poNumber,
        'cust_id': custId,
        'sku': sku,
      });
      print('Product inserted: $poNumber');
    } catch (e) {
      print('Error inserting product: $e');
    }
  }

  // New method to update a product
  // Sekarang menerima 'id' sebagai ID dokumen Firestore yang sebenarnya
  Future<void> updateProduct({
    required String id, // Ini adalah ID dokumen Firestore yang sebenarnya
    required String poNumber,
    required String custId,
    required String sku,
  }) async {
    try {
      await _db.collection('purchase_orders').doc(id).update({
        'po_number': poNumber,
        'cust_id': custId,
        'sku': sku,
      });
      print('Product updated: $poNumber (ID: $id)');
    } catch (e) {
      print('Error updating product: $e');
    }
  }

  // New method to delete a product
  // Sekarang menerima 'id' sebagai ID dokumen Firestore yang sebenarnya
  Future<void> deleteProduct(String id) async {
    try {
      await _db.collection('purchase_orders').doc(id).delete();
      print('Product deleted: $id');
    } catch (e) {
      print('Error deleting product: $e');
    }
  }

  // New public method to check if the 'purchase_orders' collection is empty
  Future<bool> isPurchaseOrdersCollectionEmpty() async {
    try {
      final poSnapshot = await _db.collection('purchase_orders').limit(1).get();
      return poSnapshot.docs.isEmpty;
    } catch (e) {
      print('Error checking if purchase orders collection is empty: $e');
      return true; // Asumsi kosong jika ada error untuk mencegah crash
    }
  }
}
