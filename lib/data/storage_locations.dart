import 'dart:io';

/// File that holds all trips, inside the app's private documents directory.
File tripsFile(Directory documents) => File('${documents.path}/trips.json');
