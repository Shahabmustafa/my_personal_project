class PrinterHeadModel {
  final String id;
  final String name;
  final String imageUrl;
  final String address;
  final String phoneNumber;
  final DateTime createdAt;

  PrinterHeadModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.address,
    required this.phoneNumber,
    required this.createdAt,
  });

  factory PrinterHeadModel.fromMap(Map<String, dynamic> map) {
    return PrinterHeadModel(
      id:          map['id']          as String,
      name:        map['name']        as String? ?? '',
      imageUrl:    map['image_url']   as String? ?? '',
      address:     map['address']     as String? ?? '',
      phoneNumber: map['phone_number'] as String? ?? '',
      createdAt:   DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'name':         name,
        'image_url':    imageUrl,
        'address':      address,
        'phone_number': phoneNumber,
      };
}
