import re

with open('lib/views/screens/profile_page.dart', 'r') as f:
    content = f.read()

# _buildShipmentItem arguments: trackingNumber, status, delivered, details

# Now we see that it doesn't take the image URL.
# Wait, let's just make sure we did all the image mapping right in the API or Shipments page and that's it.
# Actually, the user says "في الشحنات انا عايز يبقي الصوره ظاهره وجايه من الباك" 
# which translates to: "In the shipments [page], I want the image to be visible and coming from the backend"

