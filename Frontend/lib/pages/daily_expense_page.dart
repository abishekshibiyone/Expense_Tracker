import 'package:expense_tracker/pages/monthly_expense_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

class DailyExpensePage extends StatefulWidget {
  @override
  _DailyExpensePageState createState() => _DailyExpensePageState();
}

class _DailyExpensePageState extends State<DailyExpensePage> {
  TextEditingController dateController = TextEditingController();
  TextEditingController newItemNameController = TextEditingController();
  TextEditingController newItemPriceController = TextEditingController();
  
  Map<String, TextEditingController> quantityControllers = {};
  Map<String, double> itemPrices = {};
  bool isLoading = true;
  double totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    fetchPrices();
  }

  Future<void> fetchPrices() async {
    try {
      Map<String, double> prices = await ApiService.getMenuPrices();
      setState(() {
        itemPrices = prices;
        for (var item in prices.keys) {
          quantityControllers[item] = TextEditingController();
          quantityControllers[item]!.addListener(calculateTotal);
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void calculateTotal() {
    double total = 0.0;
    itemPrices.forEach((item, price) {
      int quantity = int.tryParse(quantityControllers[item]?.text ?? '0') ?? 0;
      total += quantity * price;
    });
    setState(() {
      totalAmount = total;
    });
  }

  void addNewItem() async {
    String name = newItemNameController.text.trim();
    String priceText = newItemPriceController.text.trim();
    if (name.isEmpty || priceText.isEmpty) return;
    
    double? price = double.tryParse(priceText);
    if (price == null || price <= 0) return;

    String message = await ApiService.addMenuItem(name, price);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

    setState(() {
      itemPrices[name] = price;
      quantityControllers[name] = TextEditingController();
      quantityControllers[name]!.addListener(calculateTotal);
      newItemNameController.clear();
      newItemPriceController.clear();
    });
  }
  

  void deleteItem(String itemName) async {
    String message = await ApiService.deleteMenuItem(itemName);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

    setState(() {
      itemPrices.remove(itemName);
      quantityControllers[itemName]?.dispose();
      quantityControllers.remove(itemName);
      calculateTotal();
    });
  }

void submitExpense() async {
  Map<String, int> expenseData = {};

  for (var item in itemPrices.keys) {
    int quantity = int.tryParse(quantityControllers[item]?.text ?? '0') ?? 0;
    if (quantity > 0) {
      expenseData[item] = quantity;
    }
  }

  try {
    bool success = await ApiService.addExpense(dateController.text, expenseData);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Expense added successfully!"))
      );

      // Clear all quantity fields
      setState(() {
        for (var controller in quantityControllers.values) {
          controller.clear();
        }
        totalAmount = 0.0; // Reset total amount
      });

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add expense."))
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("An error occurred!"))
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tea & Snacks Expense')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MonthlyExpensePage()),
                      );
                    },
                    child: Text("Monthly Expense"),
                  ),
                ],
              ),
              SizedBox(height: 20,),
              buildDateField(),
              SizedBox(height: 16),
              isLoading ? Center(child: CircularProgressIndicator()) : buildItemList(),
              SizedBox(height: 10),
              Text("Total: ₹${totalAmount.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              buildAddItemForm(),
              SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: submitExpense,
                    child: Text("Submit Expense"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDateField() {
    return TextField(
      controller: dateController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: "Date",
        border: OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(Icons.calendar_today),
          onPressed: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              setState(() {
                dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
              });
            }
          },
        ),
      ),
    );
  }

  Widget buildItemList() {
    return Column(
      children: itemPrices.keys.map((item) => buildItemField(item)).toList(),
    );
  }

  Widget buildItemField(String item) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: TextField(
                controller: quantityControllers[item],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "$item (₹${itemPrices[item]?.toStringAsFixed(2) ?? 'N/A'})",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => deleteItem(item),
          ),
        ],
      ),
    );
  }

  Widget buildAddItemForm() {
    return Column(
      children: [
        TextField(
          controller: newItemNameController,
          decoration: InputDecoration(
            labelText: "Item Name",
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: newItemPriceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Price",
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: addNewItem,
          child: Text("Add Item"),
        ),
      ],
    );
  }
}
