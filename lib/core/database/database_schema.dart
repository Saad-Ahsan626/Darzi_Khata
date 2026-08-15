class DatabaseSchema {
  static const String customersTable = 'customers';
  static const String measurementsTable = 'measurements';
  static const String ordersTable = 'orders';
  static const String createCustomersTable =
      '''
    CREATE TABLE $customersTable (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      urduName TEXT,
      phone TEXT,
      address TEXT,
      imagePath TEXT,
      createdAt INTEGER NOT NULL,
      ownerId TEXT DEFAULT 'guest',
      syncStatus INTEGER DEFAULT 0
    )
  ''';

  static const String createMeasurementsTable =
      '''
    CREATE TABLE $measurementsTable (
      id TEXT PRIMARY KEY,
      customerId TEXT NOT NULL,
      garmentType TEXT NOT NULL,
      measurementData TEXT NOT NULL,
      createdAt INTEGER NOT NULL,
      ownerId TEXT DEFAULT 'guest',
      syncStatus INTEGER DEFAULT 0,
      FOREIGN KEY(customerId) REFERENCES $customersTable(id) ON DELETE CASCADE
    )
  ''';

  static const String createOrdersTable =
      '''
    CREATE TABLE $ordersTable (
      id TEXT PRIMARY KEY,
      customerId TEXT NOT NULL,
      measurementId TEXT,
      garmentType TEXT NOT NULL,
      status TEXT NOT NULL,
      deliveryDate INTEGER NOT NULL,
      totalAmount REAL NOT NULL,
      advancePaid REAL NOT NULL,
      notes TEXT,
      createdAt INTEGER NOT NULL,
      ownerId TEXT DEFAULT 'guest',
      syncStatus INTEGER DEFAULT 0,
      FOREIGN KEY(customerId) REFERENCES $customersTable(id) ON DELETE CASCADE,
      FOREIGN KEY(measurementId) REFERENCES $measurementsTable(id) ON DELETE SET NULL
    )
  ''';
}
