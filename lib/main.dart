import 'package:flutter/material.dart';

import 'app.dart';
import 'services/repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TastingRepository.instance.init();
  runApp(const TadimApp());
}
