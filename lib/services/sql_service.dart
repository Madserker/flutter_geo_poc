import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class GeofencingIteration {
  final int id;
  final String latitude;
  final String longitude;
  final String date;

  const GeofencingIteration({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.date
  });
}


class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'gpoc.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE geofencing_iterations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude TEXT,
        longitude TEXT,
        time  TEXT
      )
    ''');
  }

  Future<void> insertGeofencingIteration(Map<String, dynamic> geofencingIteration) async {
    final db = await database;
    await db.insert('geofencing_iterations', geofencingIteration, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<GeofencingIteration>> getGeofencingIterations() async {
    final db = await database;
    final geofencingIterationMaps = await db.query('geofencing_iterations');
    return [
      for (final {
        'id': id as int,
        'latitude': latitude as String,
        'longitude': longitude as String,
        'time': time as String
      } in geofencingIterationMaps)
      GeofencingIteration(id: id, latitude: latitude, longitude: longitude, date: time)
    ];
  }
}