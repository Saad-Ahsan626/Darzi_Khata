import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_khata/core/formatting/rupee_input_formatter.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_timing.dart';
import 'package:tailor_khata/features/orders/presentation/widgets/whatsapp_reminder.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';

final _today = DateTime(2026, 10, 4, 9, 41);

Order _order({
  String id = 'order',
  String status = 'Received',
  DateTime? due,
  double paid = 2000,
  DateTime? deliveredAt,
}) => Order(
  id: id,
  customerId: 'nida',
  orderNumber: 1031,
  garmentType: 'Kurta',
  status: status,
  deliveryDate: due ?? DateTime(2026, 10, 9),
  totalAmount: 3500,
  paidAmount: paid,
  createdAt: DateTime(2026, 9, 28),
  deliveredAt: deliveredAt,
);

const _shop = ShopSettings(
  shopName: 'Hassan Tailors',
  openingTime: '11:00',
  closingTime: '21:00',
);

String _message(Order order, {ShopSettings settings = _shop}) =>
    reminderMessage(
      order: order,
      customerName: 'Nida Aslam',
      orderLabel: 'TK-1031',
      settings: settings,
      today: _today,
    );

TextEditingValue _type(String text, {TextEditingValue? before}) =>
    const RupeeInputFormatter().formatEditUpdate(
      before ?? TextEditingValue.empty,
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );

void main() {
  group('order timing', () {
    test('counts whole days against the delivery date', () {
      expect(_order(due: DateTime(2026, 10, 2)).daysLate(_today), 2);
      expect(_order(due: DateTime(2026, 10, 4, 18)).daysLate(_today), 0);
      expect(_order(due: DateTime(2026, 10, 9)).daysLate(_today), -5);
    });

    test('sorts each open order into one of today, upcoming or overdue', () {
      final late = _order(due: DateTime(2026, 10, 2));
      final today = _order(due: DateTime(2026, 10, 4));
      final ahead = _order(due: DateTime(2026, 10, 9));
      expect(
        [late, today, ahead].map(
          (o) =>
              (o.isOverdue(_today), o.isDueToday(_today), o.isUpcoming(_today)),
        ),
        [(true, false, false), (false, true, false), (false, false, true)],
      );
    });

    test('a delivered order is never late', () {
      final delivered = _order(status: 'Delivered', due: DateTime(2026, 9, 1));
      expect(delivered.isOverdue(_today), isFalse);
      expect(delivered.isDueToday(_today), isFalse);
    });

    test('the worklist puts the latest and furthest along first', () {
      final orders = [
        _order(
          id: 'delivered-old',
          status: 'Delivered',
          deliveredAt: DateTime(2026, 9, 1),
        ),
        _order(id: 'ahead', due: DateTime(2026, 10, 9)),
        _order(
          id: 'today-stitching',
          status: 'Stitching',
          due: DateTime(2026, 10, 4),
        ),
        _order(
          id: 'delivered-new',
          status: 'Delivered',
          deliveredAt: DateTime(2026, 10, 3),
        ),
        _order(id: 'today-ready', status: 'Ready', due: DateTime(2026, 10, 4)),
        _order(id: 'late', due: DateTime(2026, 10, 2)),
      ]..sort(compareForWorklist);
      expect(
        [for (final order in orders) order.id],
        [
          'late',
          'today-ready',
          'today-stitching',
          'ahead',
          'delivered-new',
          'delivered-old',
        ],
      );
    });
  });

  group('reminder message', () {
    test('a ready order is ready for pickup, with the balance and hours', () {
      expect(
        _message(_order(status: 'Ready')),
        'Assalam o Alaikum Nida Aslam. Your Kurta order (TK-1031) is ready '
        'for pickup at Hassan Tailors. Balance due: Rs 1,500. Shop timings '
        '11am–9pm.',
      );
    });

    test('an order in work gives its stage and expected date', () {
      expect(
        _message(_order(status: 'Stitching', paid: 3500)),
        'Assalam o Alaikum Nida Aslam. Your Kurta order (TK-1031) at Hassan '
        'Tailors is being stitched. Expected delivery: 9 Oct.',
      );
    });

    test('a late order in work does not promise a date already gone', () {
      expect(
        _message(_order(status: 'Cutting', due: DateTime(2026, 10, 2))),
        'Assalam o Alaikum Nida Aslam. Your Kurta order (TK-1031) at Hassan '
        'Tailors is being cut. We will let you know as soon as it is ready. '
        'Balance due: Rs 1,500.',
      );
    });

    test('a delivered order asks for what is still due', () {
      expect(
        _message(_order(status: 'Delivered')),
        'Assalam o Alaikum Nida Aslam. Rs 1,500 is still due on your Kurta '
        'order (TK-1031) from Hassan Tailors. Thank you.',
      );
    });

    test('leaves out the shop name and hours until they are set', () {
      expect(
        _message(_order(status: 'Ready'), settings: const ShopSettings()),
        'Assalam o Alaikum Nida Aslam. Your Kurta order (TK-1031) is ready '
        'for pickup. Balance due: Rs 1,500.',
      );
    });

    test('shop hours read as the shop says them', () {
      expect(shopTimings(_shop), '11am–9pm');
      expect(
        shopTimings(
          const ShopSettings(openingTime: '10:30', closingTime: '20:00'),
        ),
        '10:30am–8pm',
      );
      expect(shopTimings(const ShopSettings(openingTime: '10:00')), isNull);
    });
  });

  group('WhatsApp link', () {
    test('opens a chat with the number in international form', () {
      final link = whatsAppLink('0302 118 4532', 'Balance due: Rs 1,500.')!;
      expect(link.toString(), startsWith('https://wa.me/923021184532?text='));
      expect(link.queryParameters['text'], 'Balance due: Rs 1,500.');
      expect(whatsAppLink('+92 302 1184532', 'Hi')!.path, '/923021184532');
    });

    test('needs a full number', () {
      expect(whatsAppLink(null, 'Hi'), isNull);
      expect(whatsAppLink('0302', 'Hi'), isNull);
    });
  });

  group('rupee input', () {
    test('groups thousands as they are typed', () {
      expect(_type('12500').text, '12,500');
      expect(_type('1250000').text, '1,250,000');
      expect(_type('0042').text, '42');
      expect(_type('').text, '');
    });

    test('keeps the cursor after the same digit', () {
      // A 1 typed at the front of 125,000 moves every separator.
      final value = const RupeeInputFormatter().formatEditUpdate(
        const TextEditingValue(text: '125,000'),
        const TextEditingValue(
          text: '1125,000',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      expect(value.text, '1,125,000');
      expect(value.selection.baseOffset, 1);
    });

    test('refuses more digits than allowed', () {
      final before = _type('123456789');
      expect(_type('1234567890', before: before).text, '123,456,789');
    });

    test('reads back as a whole number', () {
      expect(parseRupees('12,500'), 12500);
      expect(parseRupees(''), isNull);
      expect(rupeesInputText(6500), '6,500');
      expect(rupeesInputText(null), '');
    });
  });
}
