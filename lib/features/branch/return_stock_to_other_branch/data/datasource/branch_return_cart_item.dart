/// Local cart item used in the branch-to-branch stock return UI before
/// saving — same shape as [BranchTransferCartItem] (assign_stock_to_other_branch
/// feature) but kept independent since returns are backed by their own
/// tables/RPCs (branch_stock_returns / create_branch_stock_return).
class BranchReturnCartItem {
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

  BranchReturnCartItem({
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

  BranchReturnCartItem copyWith({int? quantity}) {
    return BranchReturnCartItem(
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
