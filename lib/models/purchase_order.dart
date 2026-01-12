class PurchaseOrder {
  final String poNumber;
  final String custId;
  final String sku;

  PurchaseOrder({
    required this.poNumber,
    required this.custId,
    required this.sku,
  });

  // Factory constructor untuk membuat PurchaseOrder dari Map (misalnya dari Firestore)
  factory PurchaseOrder.fromMap(Map<String, dynamic> data) {
    return PurchaseOrder(
      poNumber: data['po_number'] ?? '',
      custId: data['cust_id'] ?? '',
      sku: data['sku'] ?? '',
    );
  }

  // Method untuk mengubah PurchaseOrder menjadi Map (untuk disimpan ke Firestore)
  Map<String, dynamic> toMap() {
    return {
      'po_number': poNumber,
      'cust_id': custId,
      'sku': sku,
    };
  }
}
