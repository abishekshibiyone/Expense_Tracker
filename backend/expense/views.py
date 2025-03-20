import json
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import *
from django.utils.dateparse import parse_date
from django.views.decorators.csrf import csrf_exempt
from .serializers import *
from django.http import JsonResponse
from rest_framework import status
from django.db.models import Sum
from django.views import View


@api_view(['POST'])
def add_expense(request):
    try:
        data = request.data
        date = data.get("date")
        expenses = data.get("expenses")  # Expecting a dictionary { "Tea": 1, "Coffee": 1 }

        if not date or not expenses:
            return Response({"error": "Missing data"}, status=400)

        # Check if an entry for this date already exists
        daily_expense, created = DailyExpense.objects.get_or_create(date=date)

        # Update items
        daily_expense.items.update(expenses)
        daily_expense.calculate_total()  # Recalculate total
        daily_expense.save()

        return Response({"message": "Expense updated successfully!"}, status=201)

    except Exception as e:
        return Response({"error": str(e)}, status=500)
    

@api_view(['GET'])
def get_monthly_expenses(request, month):
    expenses = DailyExpense.objects.filter(date__startswith=month)
    serializer = DailyExpenseSerializer(expenses, many=True)
    return Response(serializer.data)

@csrf_exempt  # Disable CSRF for testing purposes (remove in production)
def save_expense(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)

            date = data.get("date")
            tea_count = data.get("tea_count", 0)
            coffee_count = data.get("coffee_count", 0)
            snacks_count = data.get("snacks_count", 0)
            total_amount = data.get("total_amount", 0)

            # Save to database
            expense, created = DailyExpense.objects.get_or_create(date=date)
            expense.tea_count = tea_count
            expense.coffee_count = coffee_count
            expense.snacks_count = snacks_count
            expense.total_amount = total_amount
            expense.save()

            return JsonResponse({"message": "Expense saved successfully!"}, status=201)
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=400)

    return JsonResponse({"error": "Invalid request method"}, status=405)



@api_view(['DELETE'])
def delete_expense(request, id):
    try:
        expense = DailyExpense.objects.get(id=id)
        expense.delete()
        return Response({"message": "Expense deleted successfully"}, status=status.HTTP_200_OK)
    except DailyExpense.DoesNotExist:
        return Response({"error": "Expense not found"}, status=status.HTTP_404_NOT_FOUND)

@api_view(['POST'])
def add_menu_item(request):
    serializer = MenuItemSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def delete_menu_item(request):
    name = request.data.get("name")
    try:
        item = MenuItem.objects.get(name=name)
        item.delete()
        return Response({"message": "Item deleted successfully"}, status=status.HTTP_200_OK)
    except MenuItem.DoesNotExist:
        return Response({"error": "Item not found"}, status=status.HTTP_404_NOT_FOUND)


def get_menu_items(request):
    """API to retrieve all menu items and their prices"""
    items = MenuItem.objects.all().values("name", "price")
    return JsonResponse(list(items), safe=False)

@api_view(['PUT'])
def update_expense(request, id):
    try:
        expense = DailyExpense.objects.get(id=id)
        data = request.data.get('items', {})

        expense.items = data  # Store the updated items
        expense.save()

        return Response({"message": "Expense updated successfully"}, status=status.HTTP_200_OK)
    except DailyExpense.DoesNotExist:
        return Response({"error": "Expense not found"}, status=status.HTTP_404_NOT_FOUND)

@api_view(['GET'])
def get_menu_items(request):
    menu_items = MenuItem.objects.all()
    serializer = MenuItemSerializer(menu_items, many=True)
    return Response(serializer.data)