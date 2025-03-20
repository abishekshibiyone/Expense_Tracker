from rest_framework import serializers
from .models import DailyExpense, MenuItem, MonthlyExpense


class MenuItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = MenuItem
        fields = '__all__'


class DailyExpenseSerializer(serializers.ModelSerializer):
    total_amount = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)

    class Meta:
        model = DailyExpense
        fields = ['id', 'date', 'items', 'total_amount']

    def create(self, validated_data):
        """Override create method to ensure total amount is calculated."""
        instance = DailyExpense.objects.create(**validated_data)
        instance.calculate_total()
        return instance

    def update(self, instance, validated_data):
        """Override update method to recalculate total on update."""
        instance.items = validated_data.get('items', instance.items)
        instance.calculate_total()
        instance.save()
        return instance


class MonthlyExpenseSerializer(serializers.ModelSerializer):
    total_expense = serializers.FloatField()  # Ensure it is serialized as float

    class Meta:
        model = MonthlyExpense
        fields = ['id', 'month', 'items', 'total_expense']
