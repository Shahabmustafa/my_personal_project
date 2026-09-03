import 'package:flutter/material.dart';

/// Sale / Return / Exchange report screens ki table ka common shell —
/// full width le, andar se vertical + (zaroorat par) horizontal scroll,
/// aur rows ki spacing thori khuli rakhi hai.
class ReportTableShell extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  const ReportTableShell({super.key, required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: c.maxWidth),
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFF7F8FC)),
                headingRowHeight: 48,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 60,
                columnSpacing: 34,
                horizontalMargin: 20,
                columns: columns,
                rows: rows,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
