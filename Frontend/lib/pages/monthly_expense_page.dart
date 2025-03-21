import 'package:expense_tracker/pages/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthlyExpensePage extends StatefulWidget {
  const MonthlyExpensePage({super.key});

  @override
  _MonthlyExpensePageState createState() => _MonthlyExpensePageState();
}

class _MonthlyExpensePageState extends State<MonthlyExpensePage> {
  List<Map<String, dynamic>> expenses = [];
  String currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
  int totalTea = 0, totalCoffee = 0, totalSnacks = 0;
  double totalMonthlyAmount = 0.0;
  int currentPage = 0, itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    fetchMonthlyExpense();
  }

  /// Fetches monthly total expense along with daily details
void fetchMonthlyExpense() async {
  try {
    List<dynamic> data = await ApiService.getMonthlyExpenses(currentMonth);
    setState(() {
      expenses = data.map((e) => {
        'id': e['id'],
        'date': e['date'] ?? 'N/A',
        'items': e['items'] ?? {},
        'total_amount': e['total_amount'] as double,  // Ensure it's treated as double
      }).toList();

      expenses.sort((a, b) => b['date'].compareTo(a['date']));

      // Reset totals
      totalTea = 0;
      totalCoffee = 0;
      totalSnacks = 0;
      totalMonthlyAmount = 0.0;

   for (var e in expenses) {
  totalTea += (e['items'].containsKey('Tea') ? (e['items']['Tea'] as num) : 0).toInt();
  totalCoffee += (e['items'].containsKey('Coffee') ? (e['items']['Coffee'] as num) : 0).toInt();
  totalSnacks += (e['items'].containsKey('Snacks') ? (e['items']['Snacks'] as num) : 0).toInt();
  totalMonthlyAmount += (e['total_amount'] as num).toDouble();  // Ensure it's treated as a double
}

    });
  } catch (e) {
  }
}

void editExpense(int index) async {
  Map<String, dynamic> expense = expenses[index];

  // Fetch all menu items from the backend
  List<dynamic> menuItems = await ApiService.fetchMenuItems();

  Map<String, TextEditingController> controllers = {};

  // Populate controllers with existing item counts
  expense['items'].forEach((key, value) {
    controllers[key] = TextEditingController(text: value.toString());
  });

  // Add new menu items to the list if not already in the expense
  for (var item in menuItems) {
    if (!controllers.containsKey(item['name'])) {
      controllers[item['name']] = TextEditingController();
    }
  }

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Edit Expense"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: controllers.entries.map((entry) {
              return TextField(
                controller: entry.value,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "${entry.key} Count"),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Map<String, dynamic> updatedItems = {};

              controllers.forEach((key, value) {
                int count = int.tryParse(value.text) ?? 0;
                if (count > 0) {
                  updatedItems[key] = count;
                }
              });

              Map<String, dynamic> updatedData = {
                "items": updatedItems,
              };

              await ApiService.updateExpense(expense['id'], updatedData);
              fetchMonthlyExpense(); // Refresh the list
              Navigator.pop(context);
            },
            child: Text("Update"),
          ),
        ],
      );
    },
  );
}

 

  void deleteExpense(int index) async {
    int id = expenses[index]['id'];
    await ApiService.deleteExpense(id);
    setState(() {
      expenses.removeAt(index);
      fetchMonthlyExpense(); // Refresh after deletion
    });
  }

  void nextPage() {
    if ((currentPage + 1) * itemsPerPage < expenses.length) {
      setState(() => currentPage++);
    }
  }

  void previousPage() {
    if (currentPage > 0) {
      setState(() => currentPage--);
    }
  }

  @override
  Widget build(BuildContext context) {
    int start = currentPage * itemsPerPage;
    int end = start + itemsPerPage;
    List<Map<String, dynamic>> paginatedExpenses =
        expenses.sublist(start, end > expenses.length ? expenses.length : end);

    return Scaffold(
      appBar: AppBar(title: Text("Monthly Expense Details")),
      body: Column(
        children: [
          // Month & Year Dropdown
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: DateFormat('MMMM').format(DateTime.parse("$currentMonth-01")),
                    onChanged: (String? newMonth) {
                      setState(() {
                        String currentYear = currentMonth.split('-')[0];
                        currentMonth = "$currentYear-${DateFormat('MM').format(DateFormat('MMMM').parse(newMonth!))}";
                        fetchMonthlyExpense();
                      });
                    },
                    items: List.generate(12, (index) {
                      DateTime date = DateTime(2000, index + 1, 1);
                      return DropdownMenuItem<String>(
                        value: DateFormat('MMMM').format(date),
                        child: Text(DateFormat('MMMM').format(date)),
                      );
                    }),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: currentMonth.split('-')[0],
                    onChanged: (String? newYear) {
                      setState(() {
                        String currentMonthPart = currentMonth.split('-')[1];
                        currentMonth = "$newYear-$currentMonthPart";
                        fetchMonthlyExpense();
                      });
                    },
                    items: List.generate(20, (index) {
                      String year = (DateTime.now().year - 10 + index).toString();
                      return DropdownMenuItem<String>(
                        value: year,
                        child: Text(year),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // Monthly Summary Card
          Card(
            margin: EdgeInsets.all(16),
            elevation: 5,
            color: Colors.lightBlue[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Summary for ${DateFormat('MMMM yyyy').format(DateTime.parse("$currentMonth-01"))}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text("☕ Tea: $totalTea", style: TextStyle(fontSize: 16)),
                  Text("☕ Coffee: $totalCoffee", style: TextStyle(fontSize: 16)),
                  Text("🍪 Snacks: $totalSnacks", style: TextStyle(fontSize: 16)),
                  Divider(),
                  Text(
                    "💰 Total Expense: ₹${totalMonthlyAmount.toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
Expanded(
  child: SingleChildScrollView(
    scrollDirection: Axis.vertical, // Enable vertical scrolling
    child: Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal, // Enable horizontal scrolling
          child: DataTable(
            columnSpacing: 20, // Adjust spacing between columns
            columns: [
              DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Items', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: paginatedExpenses.map((e) => DataRow(
              cells: [
                DataCell(Text(e['date'] ?? 'N/A')),
                DataCell(
                  SizedBox(
                    width: 120, // Limit the width of the "Items" column
                    height: 100, // Set a fixed height to allow scrolling
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: e['items'].entries.map<Widget>((entry) => 
                          Text("${entry.key}: ${entry.value}")
                        ).toList(),
                      ),
                    ),
                  ),
                ),
                DataCell(Text("₹${e['total_amount'].toStringAsFixed(2)}")),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min, // Prevents overflow in Row
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                         onPressed: () => editExpense(expenses.indexOf(e)), // ✅ Calls edit function
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteExpense(expenses.indexOf(e)),
                      ),
                    ],
                  ),
                ),
              ],
            )).toList(),

            
          ),
        ),
      ],
    ),
  ),
),

          // Pagination Controls


        ],
      ),
    );
  }
}
