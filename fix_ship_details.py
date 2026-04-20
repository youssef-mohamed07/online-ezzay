import re

with open('lib/views/screens/shipment_details_page.dart', 'r') as f:
    content = f.read()

# Fix properties
content = content.replace("final String widget.trackingNumber;", "final String trackingNumber;")
content = content.replace("final String widget.status;", "final String status;")
content = content.replace("final String widget.weight;", "final String weight;")
content = content.replace("final String widget.date;", "final String date;")

# Fix constructor
content = content.replace("required this.widget.trackingNumber,", "required this.trackingNumber,")
content = content.replace("required this.widget.status,", "required this.status,")
content = content.replace("required this.widget.weight,", "required this.weight,")
content = content.replace("required this.widget.date,", "required this.date,")

with open('lib/views/screens/shipment_details_page.dart', 'w') as f:
    f.write(content)

