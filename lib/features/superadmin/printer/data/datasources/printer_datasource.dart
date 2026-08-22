import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/printer_head_model.dart';
import '../models/assign_printer_model.dart';

class PrinterDatasource {
  final SupabaseClient _client;
  PrinterDatasource(this._client);

  static const _bucket = 'printer-images';

  Future<String> uploadImage({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final path = 'printer-heads/$fileName';
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  // ─── PRINTER HEADS ───────────────────────────────────────────────────────────

  Future<List<PrinterHeadModel>> fetchPrinterHeads() async {
    final response = await _client
        .from('printer_heads')
        .select('*')
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => PrinterHeadModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> insertPrinterHead({
    required String name,
    required String imageUrl,
    required String address,
    required String phoneNumber,
  }) async {
    await _client.from('printer_heads').insert({
      'name':         name,
      'image_url':    imageUrl,
      'address':      address,
      'phone_number': phoneNumber,
    });
  }

  Future<void> deletePrinterHead(String id) async {
    await _client.from('printer_heads').delete().eq('id', id);
  }

  // ─── ASSIGN PRINTER ──────────────────────────────────────────────────────────

  Future<List<AssignPrinterModel>> fetchAssignedPrinters() async {
    final response = await _client
        .from('assign_printer')
        .select(
          '*, branches(branch_name, address, city), printer_heads(name, image_url, address, phone_number)',
        )
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => AssignPrinterModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> insertAssignPrinter({
    required String branchId,
    required String printerHeadId,
  }) async {
    await _client.from('assign_printer').insert({
      'branch_id':       branchId,
      'printer_head_id': printerHeadId,
    });
  }

  Future<void> deleteAssignPrinter(String id) async {
    await _client.from('assign_printer').delete().eq('id', id);
  }
}
