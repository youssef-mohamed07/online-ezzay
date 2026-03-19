enum ShipmentStatus {
  processing,
  inTransit,
  delayed,
  delivered,
}

class Shipment {
  const Shipment({
    required this.id,
    required this.destination,
    required this.origin,
    required this.category,
    required this.eta,
    required this.price,
    required this.status,
    required this.progress,
  });

  final String id;
  final String destination;
  final String origin;
  final String category;
  final DateTime eta;
  final double price;
  final ShipmentStatus status;
  final double progress;
}
