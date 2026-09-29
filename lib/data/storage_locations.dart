import 'dart:io';

/// File that holds all trips, inside the app's private documents directory.
File tripsFile(Directory documents) => File('${documents.path}/trips.json');

/// File that holds the entries of all trips, next to [tripsFile].
File entriesFile(Directory documents) =>
    File('${documents.path}/entries.json');
