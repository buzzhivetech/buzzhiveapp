/// Route path constants.
class Routes {
  Routes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String analytics = '/analytics';
  static const String sensors = '/sensors';
  static const String addSensor = '/sensors/add';
  static String sensorDetail(String id) => '/sensors/$id';
  static const String map = '/map';
  static const String alerts = '/alerts';
  static const String settings = '/settings';
  static const String profileEdit = '/profile/edit';
}
