import 'package:flutter/foundation.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:ta_client/app/app.dart';
import 'package:ta_client/bootstrap.dart';

void main() async {
  if (!kIsWeb) {
    await TeXRenderingServer.start();
  }
  await bootstrap(() => const App());
}
