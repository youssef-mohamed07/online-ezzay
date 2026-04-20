import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

import 'core/app.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/shipment_provider.dart';
import 'providers/dashboard_provider.dart';

const String _defaultStripePublishableKey =
    'pk_test_TYooMQauvdEDq54NiTphI7jx';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const configuredPk = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: _defaultStripePublishableKey,
  );

  Stripe.publishableKey = configuredPk;
  await Stripe.instance.applySettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ShipmentProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: const OnlineEzzyApp(),

    ),
  );
}
