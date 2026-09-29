import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'data/json_file_entry_repository.dart';
import 'data/json_file_trip_repository.dart';
import 'data/random_id.dart';
import 'data/storage_locations.dart';
import 'ui/app.dart';
import 'ui/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final documents = await getApplicationDocumentsDirectory();
  runApp(
    TrailtaleApp(
      services: AppServices(
        tripRepository: JsonFileTripRepository(tripsFile(documents)),
        entryRepository: JsonFileEntryRepository(entriesFile(documents)),
        newId: randomId,
      ),
    ),
  );
}
