class DatabaseSchema {
  static const int version = 4;

  static const String customersTable = 'customers';
  static const String measurementsTable = 'measurements';
  static const String ordersTable = 'orders';
  static const String paymentsTable = 'payments';
  static const String orderStatusEventsTable = 'order_status_events';
  static const String shopSettingsTable = 'shop_settings';

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
      syncStatus INTEGER DEFAULT 0,
      note TEXT
    )
  ''';

  /// One row per customer, garment and fit profile. measurementData is a JSON
  /// map of field key to inches; unit is the unit the profile is shown in.
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
      fitProfile TEXT NOT NULL DEFAULT 'Formal Fit',
      unit TEXT NOT NULL DEFAULT 'in',
      note TEXT,
      updatedAt INTEGER,
      FOREIGN KEY(customerId) REFERENCES $customersTable(id) ON DELETE CASCADE
    )
  ''';

  static const String createMeasurementProfileIndex =
      '''
    CREATE UNIQUE INDEX idx_measurements_profile
    ON $measurementsTable(customerId, garmentType, fitProfile)
  ''';

  /// status and advancePaid mirror the latest status event and the sum of the
  /// order's payments; both are written together with those rows.
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
      deliveredAt INTEGER,
      ownerId TEXT DEFAULT 'guest',
      syncStatus INTEGER DEFAULT 0,
      orderNumber INTEGER,
      pieces INTEGER NOT NULL DEFAULT 1,
      fabric TEXT,
      FOREIGN KEY(customerId) REFERENCES $customersTable(id) ON DELETE CASCADE,
      FOREIGN KEY(measurementId) REFERENCES $measurementsTable(id) ON DELETE SET NULL
    )
  ''';

  static const String createOrderNumberIndex =
      '''
    CREATE UNIQUE INDEX idx_orders_number ON $ordersTable(orderNumber)
  ''';

  static const String createPaymentsTable =
      '''
    CREATE TABLE $paymentsTable (
      id TEXT PRIMARY KEY,
      orderId TEXT NOT NULL,
      amount REAL NOT NULL,
      method TEXT NOT NULL,
      isAdvance INTEGER NOT NULL DEFAULT 0,
      paidAt INTEGER NOT NULL,
      ownerId TEXT DEFAULT 'guest',
      syncStatus INTEGER DEFAULT 0,
      FOREIGN KEY(orderId) REFERENCES $ordersTable(id) ON DELETE CASCADE
    )
  ''';

  static const String createPaymentsOrderIndex =
      '''
    CREATE INDEX idx_payments_order ON $paymentsTable(orderId)
  ''';

  static const String createPaymentsPaidAtIndex =
      '''
    CREATE INDEX idx_payments_paid_at ON $paymentsTable(paidAt)
  ''';

  static const String createOrderStatusEventsTable =
      '''
    CREATE TABLE $orderStatusEventsTable (
      id TEXT PRIMARY KEY,
      orderId TEXT NOT NULL,
      status TEXT NOT NULL,
      changedAt INTEGER NOT NULL,
      ownerId TEXT DEFAULT 'guest',
      syncStatus INTEGER DEFAULT 0,
      FOREIGN KEY(orderId) REFERENCES $ordersTable(id) ON DELETE CASCADE
    )
  ''';

  static const String createOrderStatusEventsIndex =
      '''
    CREATE INDEX idx_status_events_order
    ON $orderStatusEventsTable(orderId, changedAt)
  ''';

  /// A single row (id 1) holding the shop profile and the order-number counter.
  static const String createShopSettingsTable =
      '''
    CREATE TABLE $shopSettingsTable (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      shopName TEXT NOT NULL DEFAULT '',
      ownerName TEXT NOT NULL DEFAULT '',
      phone TEXT NOT NULL DEFAULT '',
      address TEXT NOT NULL DEFAULT '',
      openingTime TEXT,
      closingTime TEXT,
      orderPrefix TEXT NOT NULL DEFAULT 'TK-',
      nextOrderNumber INTEGER NOT NULL DEFAULT 1,
      defaultUnit TEXT NOT NULL DEFAULT 'in'
    )
  ''';

  static const String insertShopSettingsRow =
      '''
    INSERT INTO $shopSettingsTable (id) VALUES (1)
  ''';

  /// Tables and indexes introduced in version 4, shared by new databases and
  /// the upgrade from version 3.
  static const List<String> createLedgerStatements = [
    createPaymentsTable,
    createPaymentsOrderIndex,
    createPaymentsPaidAtIndex,
    createOrderStatusEventsTable,
    createOrderStatusEventsIndex,
    createShopSettingsTable,
    insertShopSettingsRow,
  ];

  /// Statements that create a new database, in order.
  static const List<String> createStatements = [
    createCustomersTable,
    createMeasurementsTable,
    createMeasurementProfileIndex,
    createOrdersTable,
    createOrderNumberIndex,
    ...createLedgerStatements,
  ];
}
