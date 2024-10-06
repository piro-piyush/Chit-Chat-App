import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> isInternet() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi) {
    return true;  // Connected to the internet
  } else {
    return false; // Not connected
  }
}