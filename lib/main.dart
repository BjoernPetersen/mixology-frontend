import 'package:frontend/ui/app.dart';

const refreshToken = null;

void main() {
  MixologyApp.run(
    Uri.https('api.mix.bembel.party'),
    refreshToken: refreshToken,
  );
}
