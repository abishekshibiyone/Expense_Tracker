from django.contrib import admin

from .models import *

# Register your models here.

admin.site.register(DailyExpense)
admin.site.register(MonthlyExpense)
admin.site.register(MenuItem)