import 'package:frontend/ui/app.dart';

const refreshToken = null;

void main() {
  MixologyApp.run(
    apiBaseUrl: Uri.https('mix-api.bembel.party'),
    refreshToken: refreshToken,
  );
}
