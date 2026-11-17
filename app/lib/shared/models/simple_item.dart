class SimpleItem {
  const SimpleItem({
    required this.uid,
    required this.productId,
    required this.title,
    required this.quantity,
    required this.unitPrice,
  });

  final String uid;
  final String productId;
  final String title;
  final int quantity;
  final double unitPrice;

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'productId': productId,
    'title': title,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };
}
