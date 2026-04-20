import re

with open("lib/views/screens/home_page.dart", "r") as f:
    content = f.read()

# Wrap _ActiveShipmentCard
content = content.replace("const _ActiveShipmentCard(),", "const Consumer<DashboardProvider>(builder: (context, dashboard, _) => _ActiveShipmentCard(dashboard: dashboard,)),")
content = content.replace("const _WarehouseOrderCard", "const Consumer<DashboardProvider>(builder: (context, dashboard, _) => _WarehouseOrderCard(dashboard: dashboard,\n")
# Actually, I should just modify _ActiveShipmentCard implementation directly

old_card = """class _ActiveShipmentCard extends StatelessWidget {
  const _ActiveShipmentCard();"""
new_card = """class _ActiveShipmentCard extends StatelessWidget {
  const _ActiveShipmentCard();"""

with open("lib/views/screens/home_page.dart", "w") as f:
    f.write(content)
