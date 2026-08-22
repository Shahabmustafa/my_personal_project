import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/printer_datasource.dart';
import '../../data/repositories/printer_repository.dart';
import '../../data/models/printer_head_model.dart';
import '../../data/models/assign_printer_model.dart';

final printerDatasourceProvider = Provider<PrinterDatasource>(
  (_) => PrinterDatasource(Supabase.instance.client),
);

final printerRepositoryProvider = Provider<PrinterRepository>(
  (ref) => PrinterRepository(ref.watch(printerDatasourceProvider)),
);

final printerHeadsProvider = FutureProvider<List<PrinterHeadModel>>(
  (ref) => ref.watch(printerRepositoryProvider).getPrinterHeads(),
);

final assignedPrintersProvider = FutureProvider<List<AssignPrinterModel>>(
  (ref) => ref.watch(printerRepositoryProvider).getAssignedPrinters(),
);
