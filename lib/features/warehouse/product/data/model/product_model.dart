class ProductModel {
  final String id;
  final String articleName;
  final double salePrice;
  final double purchasePrice;
  final String imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductModel({
    required this.id,
    required this.articleName,
    this.salePrice = 0,
    this.purchasePrice = 0,
    this.imageUrl = '',
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      articleName: json['article_name'] ?? '',
      salePrice: (json['sale_price'] as num?)?.toDouble() ?? 0,
      purchasePrice: (json['purchase_price'] as num?)?.toDouble() ?? 0,
      imageUrl: json['image_url'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'article_name': articleName,
        'sale_price': salePrice,
        'purchase_price': purchasePrice,
        'image_url': imageUrl,
      };

  ProductModel copyWith({
    String? id,
    String? articleName,
    double? salePrice,
    double? purchasePrice,
    String? imageUrl,
  }) {
    return ProductModel(
      id: id ?? this.id,
      articleName: articleName ?? this.articleName,
      salePrice: salePrice ?? this.salePrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
