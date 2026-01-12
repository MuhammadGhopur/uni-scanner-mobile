import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import '../models/purchase_order.dart'; // Import model PurchaseOrder

class CsvToFirestoreImporter {
  static Future<List<PurchaseOrder>> importCsvToPurchaseOrders() async {
    try {
      final csvString = await rootBundle.loadString('assets/po_data.csv');
      List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);

      List<PurchaseOrder> purchaseOrders = [];

      // Assuming the first row is header and actual data starts from the third row (index 2)
      for (int i = 2; i < csvTable.length; i++) {
        final cols = csvTable[i];

        if (cols.length < 3) continue;

        purchaseOrders.add(PurchaseOrder(
          poNumber: cols[0].toString().trim(),
          custId: cols[1].toString().trim(),
          sku: cols[2].toString().trim(),
        ));
      }
      print('${purchaseOrders.length} purchase orders parsed from assets/po_data.csv');
      return purchaseOrders;
    } catch (e) {
      print('Error parsing CSV to PurchaseOrders: $e');
      return [];
    }
  }
}
