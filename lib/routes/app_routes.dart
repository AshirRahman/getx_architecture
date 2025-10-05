import 'package:get/get.dart';
import '../features/home/screen/home_screen.dart';

class AppRoute {
  static String homeScreen = "/homeScreen";

  static String getHomeScreen() => homeScreen;

  static List<GetPage> routes = [
    GetPage(name: homeScreen, page: () => const HomeScreen()),
  ];
}
