import 'package:latlong2/latlong.dart';

class ShopBranch {
  final String id;
  final String name;
  final String area;
  final String city;
  final String address;
  final String phone;

  /// International format without "+" or spaces (e.g. 923001234567) — used for wa.me links.
  final String whatsapp;
  final String hours;
  final double lat;
  final double lng;

  const ShopBranch({
    required this.id,
    required this.name,
    required this.area,
    required this.city,
    required this.address,
    required this.phone,
    required this.whatsapp,
    required this.hours,
    required this.lat,
    required this.lng,
  });

  LatLng get location => LatLng(lat, lng);

  Uri get directionsUrl => Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
}

class ShoeCategory {
  final String id;
  final String name;
  final String tagline;
  final String image;

  const ShoeCategory({required this.id, required this.name, required this.tagline, required this.image});
}

class Shoe {
  final String id;
  final String name;
  final String categoryId;
  final double price;

  /// Price before discount; shown struck through when set.
  final double? oldPrice;
  final List<int> sizes;
  final String image;
  final String description;
  final bool isNew;

  const Shoe({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    this.oldPrice,
    required this.sizes,
    required this.image,
    this.description = '',
    this.isNew = false,
  });

  int? get discountPercent =>
      oldPrice == null || oldPrice! <= price ? null : ((1 - price / oldPrice!) * 100).round();
}

/// "Rs. 4,500"
String formatPrice(double value) {
  final digits = value.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return 'Rs. $buf';
}
