class AssignPrinterModel {
  final String id;
  final String branchId;
  final String branchName;
  final String branchAddress;
  final String branchCity;
  final String printerHeadId;
  final String printerName;
  final String printerImageUrl;
  final String printerAddress;
  final String printerPhone;
  final DateTime createdAt;

  AssignPrinterModel({
    required this.id,
    required this.branchId,
    required this.branchName,
    this.branchAddress = '',
    this.branchCity = '',
    required this.printerHeadId,
    required this.printerName,
    this.printerImageUrl = '',
    this.printerAddress = '',
    this.printerPhone = '',
    required this.createdAt,
  });

  factory AssignPrinterModel.fromMap(Map<String, dynamic> map) {
    final branch  = map['branches']      as Map<String, dynamic>? ?? {};
    final printer = map['printer_heads'] as Map<String, dynamic>? ?? {};

    return AssignPrinterModel(
      id:              map['id']             as String,
      branchId:        map['branch_id']      as String,
      branchName:      branch['branch_name'] as String? ?? '',
      branchAddress:   branch['address']     as String? ?? '',
      branchCity:      branch['city']        as String? ?? '',
      printerHeadId:   map['printer_head_id'] as String,
      printerName:     printer['name']       as String? ?? '',
      printerImageUrl: printer['image_url']  as String? ?? '',
      printerAddress:  printer['address']    as String? ?? '',
      printerPhone:    printer['phone_number'] as String? ?? '',
      createdAt:       DateTime.parse(map['created_at'] as String),
    );
  }
}
