/// Local cart item used in the branch-to-branch transfer UI before saving —
/// mirrors `AssignCartItem` (warehouse->branch feature) but sourced from
/// this branch's own `branch_stock_inventory` instead of a warehouse.
class BranchTransferCartItem {
  final String stockId;
  final String barcode;
  final String productId;
  final String productName;
  final String sizeId;
  final String sizeName;
  final String colorId;
  final String colorName;
  final String brandId;
  final String brandName;
  final String categoryId;
  final String categoryName;
  final String typeId;
  final String typeName;
  final int availableStock; // is branch mein available qty
  int quantity;
  final double salePrice;
  final double purchasePrice;
  final double discount;

  BranchTransferCartItem({
    required this.stockId,
    required this.barcode,
    required this.productId,
    required this.productName,
    required this.sizeId,
    required this.sizeName,
    required this.colorId,
    required this.colorName,
    required this.brandId,
    required this.brandName,
    required this.categoryId,
    required this.categoryName,
    required this.typeId,
    required this.typeName,
    required this.availableStock,
    required this.quantity,
    required this.salePrice,
    required this.purchasePrice,
    this.discount = 0,
  });

  double get lineTotal => salePrice * quantity;

  BranchTransferCartItem copyWith({int? quantity}) {
    return BranchTransferCartItem(
      stockId: stockId,
      barcode: barcode,
      productId: productId,
      productName: productName,
      sizeId: sizeId,
      sizeName: sizeName,
      colorId: colorId,
      colorName: colorName,
      brandId: brandId,
      brandName: brandName,
      categoryId: categoryId,
      categoryName: categoryName,
      typeId: typeId,
      typeName: typeName,
      availableStock: availableStock,
      quantity: quantity ?? this.quantity,
      salePrice: salePrice,
      purchasePrice: purchasePrice,
      discount: discount,
    );
  }
}
