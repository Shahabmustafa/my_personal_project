import 'package:flutter/material.dart';

/// Backend-side pagination control — data server se page-by-page (`.range()`)
/// aata hai, ye bar sirf current/total page dikhata hai aur prev/next se
/// notifier.goToPage() call karta hai.
class ReportPaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final int totalCount;
  final int pageSize;
  final void Function(int page) onPageChange;

  const ReportPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.pageSize,
    required this.onPageChange,
  });

  @override
  Widget build(BuildContext context) {
    final from = totalCount == 0 ? 0 : (page - 1) * pageSize + 1;
    final to = (page * pageSize).clamp(0, totalCount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Row(
        children: [
          Text('Showing $from–$to of $totalCount',
              style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3))),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: page > 1 ? () => onPageChange(page - 1) : null,
          ),
          Text('Page $page of $totalPages',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: page < totalPages ? () => onPageChange(page + 1) : null,
          ),
        ],
      ),
    );
  }
}
