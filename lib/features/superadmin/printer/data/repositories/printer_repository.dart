import 'dart:typed_data';
import '../datasources/printer_datasource.dart';
import '../models/printer_head_model.dart';
import '../models/assign_printer_model.dart';

class PrinterRepository {
  final PrinterDatasource _datasource;
  PrinterRepository(this._datasource);

  Future<String> uploadImage({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) =>
      _datasource.uploadImage(fileName: fileName, bytes: bytes, mimeType: mimeType);

  // Printer Heads
  Future<List<PrinterHeadModel>> getPrinterHeads() =>
      _datasource.fetchPrinterHeads();

  Future<void> addPrinterHead({
    required String name,
    required String imageUrl,
    required String address,
    required String phoneNumber,
  }) =>
      _datasource.insertPrinterHead(
        name:        name,
        imageUrl:    imageUrl,
        address:     address,
        phoneNumber: phoneNumber,
      );

  Future<void> removePrinterHead(String id) =>
      _datasource.deletePrinterHead(id);

  // Assign Printer
  Future<List<AssignPrinterModel>> getAssignedPrinters() =>
      _datasource.fetchAssignedPrinters();

  Future<void> assignPrinter({
    required String branchId,
    required String printerHeadId,
  }) =>
      _datasource.insertAssignPrinter(
        branchId:       branchId,
        printerHeadId:  printerHeadId,
      );

  Future<void> removeAssignPrinter(String id) =>
      _datasource.deleteAssignPrinter(id);
}
