import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = "http://127.0.0.1:8000/";

class ApiService {
  static Future<Map<String, double>> getMenuPrices() async {
    final response = await http.get(Uri.parse("$baseUrl/get_menu_items/"));

    if (response.statusCode == 200) {
      List<dynamic> dataList = json.decode(response.body);
      Map<String, double> prices = {};

      for (var item in dataList) {
        String name = item['name'];
        double price = (item['price'] as num).toDouble();
        prices[name] = price;
      }

      return prices;
    } else {
      throw Exception("Failed to load menu prices");
    }
  }

  static Future<bool> addExpense(String date, Map<String, int> expenses) async {
    final url = Uri.parse("$baseUrl/add_expense/");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "date": date,
          "expenses": expenses,
        }),
      );


      return response.statusCode == 201;
    } catch (e) {

      return false;
    }
  }



static Future<List<Map<String, dynamic>>> getMonthlyExpenses(String month) async {
  final response = await http.get(Uri.parse("$baseUrl/get_monthly_expenses/$month/"));

  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    return data.map((entry) {
      Map<String, int> items = Map<String, int>.from(entry['items'] ?? {});

      return {
        'id': entry['id'],
        'date': entry['date'],
        'items': items,
        'total_amount': double.tryParse(entry['total_amount']) ?? 0.0,  // Convert to double safely
      };
    }).toList();
  } else {
    throw Exception("Failed to load monthly expenses");
  }
}




  /// Deletes an expense by ID
static Future<void> deleteExpense(int id) async {
  final url = Uri.parse("http://127.0.0.1:8000/expenses/delete/$id/"); // Ensure correct formatting
  final response = await http.delete(url);

  if (response.statusCode != 200) {
    throw Exception("Failed to delete expense");
  }
}

static Future<void> updateExpense(int id, Map<String, dynamic> updatedData) async {
  final url = Uri.parse("http://127.0.0.1:8000/expenses/update/$id/");
  
  final response = await http.put(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(updatedData),
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to update expense");
  }
}


  static Future<String> addMenuItem(String name, double price) async {
  final response = await http.post(
    Uri.parse("$baseUrl/add_menu_item/"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "name": name,
      "price": price,
    }),
  );

  if (response.statusCode == 201) {
    return "Item added successfully!";
  } else {
    return "Error adding item";
  }
}

static Future<String> deleteMenuItem(String name) async {
  final response = await http.post(
    Uri.parse("$baseUrl/delete_menu_item/"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"name": name}),
  );

  if (response.statusCode == 200) {
    return "Item deleted successfully!";
  } else {
    return "Error deleting item";
  }
}

static Future<List<dynamic>> fetchMenuItems() async {
  final url = Uri.parse("http://127.0.0.1:8000/menu-items/");
  final response = await http.get(url);

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to fetch menu items");
  }
}



}
