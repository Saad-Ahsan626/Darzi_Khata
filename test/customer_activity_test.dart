import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_khata/core/formatting/app_formats.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer_activity.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';

final _today = DateTime(2026, 10, 4, 9, 41);

Order _order(
  String customerId, {
  String status = 'Received',
  required DateTime due,
  double total = 4800,
  double paid = 0,
  DateTime? created,
}) => Order(
  id: '$customerId-$status-$due',
  customerId: customerId,
  garmentType: 'Shalwar Kameez',
  status: status,
  deliveryDate: due,
  totalAmount: total,
  paidAmount: paid,
  createdAt: created ?? DateTime(2026, 9, 28),
);

Measurement _profile(String customerId, String garment) => Measurement(
  id: '$customerId-$garment',
  customerId: customerId,
  garmentType: garment,
  measurementData: const {'chest': 40.5},
  createdAt: DateTime(2026, 9, 18),
  updatedAt: DateTime(2026, 9, 18),
);

CustomerActivity _activity({
  List<Order> orders = const [],
  List<Measurement> measurements = const [],
}) => CustomerActivity.byCustomer(
  orders: orders,
  measurements: measurements,
  today: _today,
)['faisal']!;

void main() {
  group('customer activity', () {
    test('counts orders, open orders and what is still owed', () {
      final activity = _activity(
        orders: [
          _order('faisal', due: DateTime(2026, 10, 9), paid: 2000),
          _order('faisal', status: 'Cutting', due: DateTime(2026, 10, 12)),
          // Delivered but not fully paid: no longer open, still owed.
          _order(
            'faisal',
            status: 'Delivered',
            due: DateTime(2026, 9, 1),
            total: 3000,
            paid: 2500,
          ),
        ],
      );
      expect(activity.orderCount, 3);
      expect(activity.openOrderCount, 2);
      expect(activity.outstanding, 2800 + 4800 + 500);
      expect(activity.isActive, isTrue);
      expect(activity.overdueDays, 0);
      expect(activity.deliveryToday, isFalse);
    });

    test('an open order due today is a delivery today, whatever the hour', () {
      final activity = _activity(
        orders: [_order('faisal', due: DateTime(2026, 10, 4, 18, 30))],
      );
      expect(activity.deliveryToday, isTrue);
      expect(activity.overdueDays, 0);
    });

    test('lateness is counted from the most overdue open order', () {
      final activity = _activity(
        orders: [
          _order('faisal', due: DateTime(2026, 10, 2)),
          _order('faisal', status: 'Ready', due: DateTime(2026, 9, 29)),
          // Delivered orders are never late.
          _order('faisal', status: 'Delivered', due: DateTime(2026, 8, 1)),
        ],
      );
      expect(activity.overdueDays, 5);
    });

    test('a customer with only paid, delivered orders is not active', () {
      final activity = _activity(
        orders: [
          _order(
            'faisal',
            status: 'Delivered',
            due: DateTime(2026, 9, 20),
            paid: 4800,
            created: DateTime(2026, 9, 12),
          ),
          _order(
            'faisal',
            status: 'Delivered',
            due: DateTime(2026, 7, 1),
            paid: 4800,
            created: DateTime(2026, 6, 20),
          ),
        ],
      );
      expect(activity.isActive, isFalse);
      expect(activity.lastOrderDate, DateTime(2026, 9, 12));
    });

    test('measurement profiles are counted per customer', () {
      final byCustomer = CustomerActivity.byCustomer(
        orders: [_order('bilal', due: DateTime(2026, 10, 9))],
        measurements: [
          _profile('faisal', 'Shalwar Kameez'),
          _profile('faisal', 'Trousers'),
          _profile('bilal', 'Kurta'),
        ],
        today: _today,
      );
      expect(byCustomer['faisal']!.measurementProfileCount, 2);
      expect(byCustomer['faisal']!.orderCount, 0);
      expect(byCustomer['bilal']!.measurementProfileCount, 1);
      expect(byCustomer['bilal']!.openOrderCount, 1);
      // Customers with nothing saved have no entry.
      expect(byCustomer.containsKey('nida'), isFalse);
    });
  });

  group('formatting', () {
    test('rupees are grouped in thousands', () {
      expect(formatRupees(0), 'Rs 0');
      expect(formatRupees(2800), 'Rs 2,800');
      expect(formatRupees(184500.0), 'Rs 184,500');
      expect(formatRupees(1250.5), 'Rs 1,250.5');
    });

    test('phone numbers are grouped for reading', () {
      expect(formatPhone('03004128876'), '0300 412 8876');
      expect(formatPhone('0300-4128876'), '0300 412 8876');
      expect(formatPhone('0304 550 11'), '0304 550 11');
      expect(formatPhone('0315'), '0315');
      expect(formatPhone(null), '');
    });

    test('a country code is read as the leading zero', () {
      expect(phoneDigits('+92 300 4128876'), '03004128876');
      expect(formatPhone('923004128876'), '0300 412 8876');
    });
  });
}
