import 'package:safishoe_app/core/service/print/receipt_options.dart';

class PrinterHeadModel {
  final String id;
  final String name;
  final String imageUrl;
  final String address;
  final String phoneNumber;
  final DateTime createdAt;

  /// Receipt header design — left | center | right, plus on/off toggles.
  final String logoPosition;
  final bool showLogo;
  final bool showName;
  final bool showPhone;
  final bool showAddress;
  final ReceiptOptions receiptOptions;

  PrinterHeadModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.address,
    required this.phoneNumber,
    required this.createdAt,
    this.logoPosition = 'center',
    this.showLogo = true,
    this.showName = true,
    this.showPhone = true,
    this.showAddress = true,
    this.receiptOptions = const ReceiptOptions(),
  });

  factory PrinterHeadModel.fromMap(Map<String, dynamic> map) {
    return PrinterHeadModel(
      id:          map['id']          as String,
      name:        map['name']        as String? ?? '',
      imageUrl:    map['image_url']   as String? ?? '',
      address:     map['address']     as String? ?? '',
      phoneNumber: map['phone_number'] as String? ?? '',
      createdAt:   DateTime.parse(map['created_at'] as String),
      logoPosition: map['logo_position'] as String? ?? 'center',
      showLogo:    map['show_logo']    as bool? ?? true,
      showName:    map['show_name']    as bool? ?? true,
      showPhone:   map['show_phone']   as bool? ?? true,
      showAddress: map['show_address'] as bool? ?? true,
      receiptOptions: ReceiptOptions.fromMap(
        map['receipt_options'] as Map<String, dynamic>?,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'name':         name,
        'image_url':    imageUrl,
        'address':      address,
        'phone_number': phoneNumber,
      };
}
