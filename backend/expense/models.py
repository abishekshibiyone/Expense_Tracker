from django.db import models

class MenuItem(models.Model):
    name = models.CharField(max_length=100, unique=True)
    price = models.FloatField()

    def __str__(self):
        return f"{self.name} - ₹{self.price}"


class DailyExpense(models.Model):
    date = models.DateField(unique=True)
    items = models.JSONField(default=dict)  # Stores expenses dynamically
    total_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)

    def calculate_total(self):
        """Calculate total expense dynamically from database prices."""
        total = 0.0
        item_prices = {item.name: item.price for item in MenuItem.objects.all()}  # Assuming MenuItem model exists

        for item, count in self.items.items():
            total += count * item_prices.get(item, 0)

        self.total_amount = total
        self.save()

    def __str__(self):
        return f"Expense on {self.date}: ₹{self.total_amount}"


class MonthlyExpense(models.Model):
    month = models.CharField(max_length=20, unique=True)  # e.g., 'March 2025'
    items = models.JSONField(default=dict)  # Dynamic storage of all items in a month
    total_expense = models.FloatField(default=0.0)

    def calculate_total(self):
        """Calculate monthly total dynamically."""
        total = sum(self.items.values())
        self.total_expense = total
        self.save()

    def __str__(self):
        return f"{self.month} - Total Expense: ₹{self.total_expense}"

