import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/sale_report_datasource.dart';
import '../../data/repository/sale_report_repository.dart';

final saleReportDatasourceProvider = Provider<SaleReportDatasource>(
  (_) => SaleReportDatasource(Supabase.instance.client),
);

final saleReportRepositoryProvider = Provider<SaleReportRepository>(
  (ref) => SaleReportRepository(ref.read(saleReportDatasourceProvider)),
);
