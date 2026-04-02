import 'package:online_ezzy/core/api_service.dart'; void main() async { var c = await ApiService.getCategories(); print(c); }
