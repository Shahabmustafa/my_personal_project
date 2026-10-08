import 'package:flutter/material.dart';

/// Sale / Return / Exchange report screens ki table ka common shell —
/// full width le, andar se vertical + (zaroorat par) horizontal scroll,
/// aur rows ki spacing thori khuli rakhi hai.
///
/// Height bounded ho (e.g. `Expanded` ke andar) to header sticky rehta hai —
/// rows neeche scroll hoti hain, header upar tikka rehta hai.
class ReportTableShell extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  const ReportTableShell({super.key, required this.columns, required this.rows});

  static const _headingHeight = 48.0;

  DataTable _table() => DataTable(
        // Row click sirf detail kholta hai — select checkbox nahi.
        showCheckboxColumn: false,
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F8FC)),
        headingRowHeight: _headingHeight,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 60,
        columnSpacing: 34,
        horizontalMargin: 20,
        columns: columns,
        rows: rows,
      );

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
            child: c.hasBoundedHeight
                ? SizedBox(
                    height: c.maxHeight,
                    child: Stack(
                      // minWidth (full width) table tak pahunche.
                      fit: StackFit.passthrough,
                      children: [
                        SingleChildScrollView(child: _table()),
                        // Sticky header: poori table ki copy, sirf heading
                        // row tak clip — is tarah column widths bilkul
                        // neeche wali table jaisi rehti hain.
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: _headingHeight + 1,
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.topLeft,
                              minHeight: 0,
                              maxHeight: double.infinity,
                              child: _table(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(child: _table()),
          ),
        ),
      ),
    );
  }
}
