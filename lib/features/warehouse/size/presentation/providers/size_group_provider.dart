import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/size_group_datasource.dart';
import '../../data/model/size_group_model.dart';

final sizeGroupDatasourceProvider =
    Provider<SizeGroupDatasource>((_) => SizeGroupDatasource());

/// Read by the Size Groups manager and the Add Stock Entry size grid.
/// Invalidate after a save/delete so both pick up the change.
final sizeGroupsProvider = FutureProvider<List<SizeGroupModel>>(
    (ref) => ref.read(sizeGroupDatasourceProvider).getAll());

/// Size labels sort as numbers ("6" before "10"); non-numeric ones go last.
int compareSizeLabels(String a, String b) {
  final na = double.tryParse(a.trim());
  final nb = double.tryParse(b.trim());
  if (na != null && nb != null) return na.compareTo(nb);
  if (na != null) return -1;
  if (nb != null) return 1;
  return a.compareTo(b);
}
