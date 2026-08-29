/// Local cart item used in the branch-to-warehouse stock return UI before
/// saving — same shape as [BranchReturnCartItem], kept independent since
/// this feature is backed by its own tables (branch_return_to_warehouse).
class BranchWarehouseReturnCartItem {
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
  final int availableStock;
  int quantity;
  final double salePrice;
  final double purchasePrice;
  final double discount;

  BranchWarehouseReturnCartItem({
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

  BranchWarehouseReturnCartItem copyWith({int? quantity}) {
    return BranchWarehouseReturnCartItem(
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
