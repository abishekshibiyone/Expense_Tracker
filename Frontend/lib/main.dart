import 'package:expense_tracker/pages/daily_expense_page.dart';
import 'package:expense_tracker/pages/monthly_expense_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DailyExpensePage()
    );
  }
}
