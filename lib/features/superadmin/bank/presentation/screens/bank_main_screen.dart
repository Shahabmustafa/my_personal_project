import 'package:flutter/material.dart';
import 'bank_heads_screen.dart';
import 'bank_entries_screen.dart';

class BankMainScreen extends StatelessWidget {
  const BankMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
          title: const Text(
            'Bank Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D3A),
            ),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF3E63DD),
            unselectedLabelColor: Color(0xFF8A8FA3),
            indicatorColor: Color(0xFF3E63DD),
            indicatorWeight: 2.5,
            labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle: TextStyle(fontSize: 14),
            tabs: [
              Tab(
                icon: Icon(Icons.account_balance_outlined, size: 18),
                text: 'Bank Heads',
              ),
              Tab(
                icon: Icon(Icons.receipt_long_outlined, size: 18),
                text: 'Bank Entries',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BankHeadsScreen(),
            BankEntriesScreen(),
          ],
        ),
      ),
    );
  }
}
