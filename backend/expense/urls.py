from django.urls import path
from .views import *

urlpatterns = [
    path('add_expense/', add_expense, name='add_expense'),
    path('get_monthly_expenses/<str:month>/', get_monthly_expenses, name='get_monthly_expenses'),
    path("save_expense/", save_expense, name="save_expense"),
    path('delete_expense/<int:id>/', delete_expense, name="delete_expense"),
    path('add_menu_item/', add_menu_item, name='add_menu_item'),
    path('delete_menu_item/', delete_menu_item, name='delete_menu_item'),
    path("get_menu_items/", get_menu_items, name="get_menu_items"),
    path('expenses/delete/<int:id>/', delete_expense, name='delete_expense'),
    path('menu-items/', get_menu_items, name='get_menu_items'),
]

