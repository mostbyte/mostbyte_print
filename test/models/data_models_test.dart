import 'package:flutter_test/flutter_test.dart';
import 'package:mostbyte_print/models/data_models/data_models.dart';

// ---------------------------------------------------------------------------
// Helper functions to build test JSON data
// ---------------------------------------------------------------------------

Map<String, dynamic> buildRoleJson({
  int id = 1,
  String nameUz = 'Kassir',
  String nameRu = 'Кассир',
  String nameEng = 'Cashier',
  String name = 'CASHIER',
}) =>
    {
      'id': id,
      'nameUz': nameUz,
      'nameRu': nameRu,
      'nameEng': nameEng,
      'name': name,
    };

Map<String, dynamic> buildFilialJson({
  int id = 10,
  String nameUz = 'Filial UZ',
  String nameRu = 'Филиал RU',
  String nameEng = 'Branch EN',
}) =>
    {
      'id': id,
      'nameUz': nameUz,
      'nameRu': nameRu,
      'nameEng': nameEng,
    };

Map<String, dynamic> buildCompanyJson({
  int id = 100,
  String name = 'TestCo',
  String address = '123 Main St',
  String inn = '1234567890',
  String type = 'LLC',
}) =>
    {
      'id': id,
      'name': name,
      'address': address,
      'inn': inn,
      'type': type,
    };

Map<String, dynamic> buildUserJson({
  String uuid = 'user-uuid-123',
  String? userName = 'jdoe',
  String firstName = 'John',
  String surname = 'Doe',
  Map<String, dynamic>? branch,
  Map<String, dynamic>? company,
  Map<String, dynamic>? role,
  String patronymic = 'Ivanovich',
  String phoneNumber = '+998901234567',
  String email = 'john@example.com',
}) =>
    {
      'uuid': uuid,
      'userName': userName,
      'firstName': firstName,
      'surname': surname,
      'branch': branch,
      'company': company,
      'role': role,
      'patronymic': patronymic,
      'phoneNumber': phoneNumber,
      'email': email,
    };

Map<String, dynamic> buildEarnedDataJson({
  double sum = 5000.0,
  double terminal = 2000.0,
  double? transferByCard,
}) {
  final json = <String, dynamic>{
    'sum': sum,
    'terminal': terminal,
  };
  if (transferByCard != null) {
    json['transfer_by_card'] = transferByCard;
  }
  return json;
}

Map<String, dynamic> buildEarnedJson({
  Map<String, dynamic>? closed,
  Map<String, dynamic>? open,
  Map<String, dynamic>? refund,
  double debt = 100.0,
  double discount = 50.0,
  double wasted = 200.0,
}) =>
    {
      'closed': closed ?? buildEarnedDataJson(sum: 5000, terminal: 2000),
      'open': open ?? buildEarnedDataJson(sum: 3000, terminal: 1000),
      'refund': refund ?? buildEarnedDataJson(sum: 500, terminal: 100),
      'debt': debt,
      'discount': discount,
      'wasted': wasted,
    };

Map<String, dynamic> buildShiftJson({
  int id = 1,
  Map<String, dynamic>? user,
  String openedAt = '2024-01-15 09:00:00',
  String? closedAt = '2024-01-15 18:00:00',
  Map<String, dynamic>? earned,
}) =>
    {
      'id': id,
      'user': user ?? buildUserJson(branch: buildFilialJson()),
      'opened_at': openedAt,
      'closed_at': closedAt,
      'earned': earned,
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // Role
  // =========================================================================
  group('Role', () {
    test('fromJson parses all fields correctly', () {
      final json = buildRoleJson();
      final role = Role.fromJson(json);

      expect(role.id, 1);
      expect(role.nameUz, 'Kassir');
      expect(role.nameRu, 'Кассир');
      expect(role.nameEn, 'Cashier');
      expect(role.role, 'CASHIER');
    });

    test('toJson produces correct keys and values', () {
      final role = Role(
        id: 2,
        nameUz: 'Admin UZ',
        nameRu: 'Админ',
        nameEn: 'Admin',
        role: 'ADMIN',
      );
      final json = role.toJson();

      expect(json['id'], 2);
      expect(json['nameUz'], 'Admin UZ');
      expect(json['nameRu'], 'Админ');
      expect(json['nameEng'], 'Admin');
      expect(json['name'], 'ADMIN');
    });

    test('fromJson -> toJson round-trip preserves data', () {
      final original = buildRoleJson();
      final role = Role.fromJson(original);
      final output = role.toJson();

      expect(output['id'], original['id']);
      expect(output['nameUz'], original['nameUz']);
      expect(output['nameRu'], original['nameRu']);
      expect(output['nameEng'], original['nameEng']);
      expect(output['name'], original['name']);
    });
  });

  // =========================================================================
  // Filial
  // =========================================================================
  group('Filial', () {
    test('fromJson parses all fields correctly', () {
      final json = buildFilialJson();
      final filial = Filial.fromJson(json);

      expect(filial.id, 10);
      expect(filial.name_uz, 'Filial UZ');
      expect(filial.name_ru, 'Филиал RU');
      expect(filial.name_en, 'Branch EN');
    });

    test('toJson produces correct keys and values', () {
      final filial = Filial(
        id: 20,
        name_uz: 'UZ',
        name_ru: 'RU',
        name_en: 'EN',
      );
      final json = filial.toJson();

      expect(json['id'], 20);
      expect(json['nameUz'], 'UZ');
      expect(json['nameRu'], 'RU');
      expect(json['nameEng'], 'EN');
    });

    test('fromJson -> toJson round-trip preserves data', () {
      final original = buildFilialJson();
      final filial = Filial.fromJson(original);
      final output = filial.toJson();

      expect(output, original);
    });
  });

  // =========================================================================
  // Company
  // =========================================================================
  group('Company', () {
    test('fromJson parses all fields correctly', () {
      final json = buildCompanyJson();
      final company = Company.fromJson(json);

      expect(company.id, 100);
      expect(company.name, 'TestCo');
      expect(company.address, '123 Main St');
      expect(company.inn, '1234567890');
      expect(company.type, 'LLC');
    });

    test('toJson produces correct keys and values', () {
      final company = Company(
        id: 200,
        name: 'AcmeCo',
        address: '456 Elm St',
        inn: '9876543210',
        type: 'OOO',
      );
      final json = company.toJson();

      expect(json['id'], 200);
      expect(json['name'], 'AcmeCo');
      expect(json['address'], '456 Elm St');
      expect(json['inn'], '9876543210');
      expect(json['type'], 'OOO');
    });

    test('fromJson -> toJson round-trip preserves data', () {
      final original = buildCompanyJson();
      final company = Company.fromJson(original);
      final output = company.toJson();

      expect(output, original);
    });
  });

  // =========================================================================
  // EarnedData
  // =========================================================================
  group('EarnedData', () {
    test('fromJson parses all fields including transferByCard', () {
      final json = buildEarnedDataJson(
        sum: 10000,
        terminal: 4000,
        transferByCard: 1500,
      );
      final data = EarnedData.fromJson(json);

      expect(data.sum, 10000.0);
      expect(data.terminal, 4000.0);
      expect(data.transferByCard, 1500.0);
    });

    test('fromJson defaults transferByCard to 0 when absent', () {
      final json = buildEarnedDataJson(sum: 8000, terminal: 3000);
      // transferByCard key is not present
      final data = EarnedData.fromJson(json);

      expect(data.sum, 8000.0);
      expect(data.terminal, 3000.0);
      expect(data.transferByCard, 0);
    });

    test('toJson includes transfer_by_card key', () {
      final data = EarnedData(sum: 1000, terminal: 500, transferByCard: 200);
      final json = data.toJson();

      expect(json['sum'], 1000);
      expect(json['terminal'], 500);
      expect(json['transfer_by_card'], 200);
    });

    test('constructor defaults transferByCard to 0', () {
      final data = EarnedData(sum: 100, terminal: 50);
      expect(data.transferByCard, 0);
    });

    test('fromJson -> toJson round-trip preserves data', () {
      final original = buildEarnedDataJson(
        sum: 7777,
        terminal: 3333,
        transferByCard: 444,
      );
      final data = EarnedData.fromJson(original);
      final output = data.toJson();

      expect(output['sum'], original['sum']);
      expect(output['terminal'], original['terminal']);
      expect(output['transfer_by_card'], original['transfer_by_card']);
    });
  });

  // =========================================================================
  // Earned
  // =========================================================================
  group('Earned', () {
    test('fromJson parses complete data', () {
      final json = buildEarnedJson(
        debt: 300,
        discount: 150,
        wasted: 75,
      );
      final earned = Earned.fromJson(json);

      expect(earned.debt, 300.0);
      expect(earned.discount, 150.0);
      expect(earned.wasted, 75.0);
      expect(earned.closed.sum, 5000.0);
      expect(earned.open.terminal, 1000.0);
      expect(earned.refund.sum, 500.0);
    });

    test('fromJson defaults closed/open/refund when null', () {
      final json = {
        'closed': null,
        'open': null,
        'refund': null,
        'debt': 0.0,
        'discount': 0.0,
        'wasted': 0.0,
      };
      final earned = Earned.fromJson(json);

      expect(earned.closed.sum, 0);
      expect(earned.closed.terminal, 0);
      expect(earned.open.sum, 0);
      expect(earned.open.terminal, 0);
      expect(earned.refund.sum, 0);
      expect(earned.refund.terminal, 0);
    });

    test('toJson produces correct structure', () {
      final earned = Earned(
        closed: EarnedData(sum: 100, terminal: 50),
        open: EarnedData(sum: 200, terminal: 80),
        refund: EarnedData(sum: 30, terminal: 10),
        debt: 20,
        discount: 5,
        wasted: 15,
      );
      final json = earned.toJson();

      expect(json['closed'], isA<Map<String, dynamic>>());
      expect(json['open'], isA<Map<String, dynamic>>());
      expect(json['refund'], isA<Map<String, dynamic>>());
      expect(json['debt'], 20);
      expect(json['discount'], 5);
      expect(json['wasted'], 15);
      expect(json['closed']['sum'], 100);
    });
  });

  // =========================================================================
  // User
  // =========================================================================
  group('User', () {
    test('fromJson parses complete JSON with all nested objects', () {
      final json = buildUserJson(
        branch: buildFilialJson(),
        company: buildCompanyJson(),
        role: buildRoleJson(),
      );
      final user = User.fromJson(json);

      expect(user.id, 'user-uuid-123');
      expect(user.username, 'jdoe');
      expect(user.firstname, 'John');
      expect(user.surname, 'Doe');
      expect(user.patronymic, 'Ivanovich');
      expect(user.phone, '+998901234567');
      expect(user.email, 'john@example.com');
      expect(user.filial, isNotNull);
      expect(user.filial!.id, 10);
      expect(user.company, isNotNull);
      expect(user.company!.name, 'TestCo');
      expect(user.role, isNotNull);
      expect(user.role!.role, 'CASHIER');
    });

    test('fromJson handles null branch, company, and role', () {
      final json = buildUserJson(
        branch: null,
        company: null,
        role: null,
      );
      final user = User.fromJson(json);

      expect(user.filial, isNull);
      expect(user.company, isNull);
      expect(user.role, isNull);
    });

    test('fromJson defaults patronymic to empty string when missing', () {
      final json = buildUserJson();
      json.remove('patronymic');
      final user = User.fromJson(json);

      expect(user.patronymic, '');
    });

    test('fromJson defaults phone to empty string when null', () {
      final json = buildUserJson();
      json['phoneNumber'] = null;
      final user = User.fromJson(json);

      expect(user.phone, '');
    });

    test('fromJson defaults email to empty string when missing', () {
      final json = buildUserJson();
      json.remove('email');
      final user = User.fromJson(json);

      expect(user.email, '');
    });

    test('toJson produces correct keys', () {
      final json = buildUserJson(
        branch: buildFilialJson(),
        company: buildCompanyJson(),
        role: buildRoleJson(),
      );
      final user = User.fromJson(json);
      final output = user.toJson();

      expect(output['uuid'], 'user-uuid-123');
      expect(output['firstName'], 'John');
      expect(output['surname'], 'Doe');
      expect(output['branch'], isA<Map<String, dynamic>>());
      expect(output['company'], isA<Map<String, dynamic>>());
      expect(output['role'], isA<Map<String, dynamic>>());
      expect(output.containsKey('filial_id'), isTrue);
    });

    test('toJson with null nested objects', () {
      final user = User(
        id: 'abc',
        firstname: 'Jane',
        surname: 'Smith',
        filial: null,
        company: null,
        role: null,
        email: '',
        patronymic: '',
        phone: '',
      );
      final output = user.toJson();

      expect(output['branch'], isNull);
      expect(output['company'], isNull);
      expect(output['role'], isNull);
      expect(output['filial_id'], isNull);
    });
  });

  // =========================================================================
  // User.isAnonymous
  // =========================================================================
  group('User.isAnonymous', () {
    test('returns true when role is ANONYMOUS', () {
      final json = buildUserJson(
        role: buildRoleJson(name: 'ANONYMOUS'),
      );
      final user = User.fromJson(json);

      expect(user.isAnonymous(), isTrue);
    });

    test('returns false when role is CASHIER', () {
      final json = buildUserJson(
        role: buildRoleJson(name: 'CASHIER'),
      );
      final user = User.fromJson(json);

      expect(user.isAnonymous(), isFalse);
    });

    test('returns false when role is null', () {
      final json = buildUserJson(role: null);
      final user = User.fromJson(json);

      expect(user.isAnonymous(), isFalse);
    });

    test('returns false for empty role name', () {
      final json = buildUserJson(
        role: buildRoleJson(name: ''),
      );
      final user = User.fromJson(json);

      expect(user.isAnonymous(), isFalse);
    });
  });

  // =========================================================================
  // Shift
  // =========================================================================
  group('Shift', () {
    test('fromJson parses complete shift with earned data', () {
      final json = buildShiftJson(
        id: 42,
        earned: buildEarnedJson(),
      );
      final shift = Shift.fromJson(json);

      expect(shift.id, 42);
      expect(shift.openedAt, '2024-01-15 09:00:00');
      expect(shift.closedAt, '2024-01-15 18:00:00');
      expect(shift.earned, isNotNull);
      expect(shift.earned!.closed.sum, 5000.0);
      expect(shift.user.firstname, 'John');
    });

    test('fromJson parses shift without earned data', () {
      final json = buildShiftJson(earned: null);
      final shift = Shift.fromJson(json);

      expect(shift.earned, isNull);
    });

    test('fromJson parses shift with null closedAt', () {
      final json = buildShiftJson(closedAt: null);
      final shift = Shift.fromJson(json);

      expect(shift.closedAt, isNull);
    });

    test('toJson produces correct structure', () {
      final json = buildShiftJson(
        id: 99,
        earned: buildEarnedJson(),
      );
      final shift = Shift.fromJson(json);
      final output = shift.toJson();

      expect(output['id'], 99);
      expect(output['opened_at'], '2024-01-15 09:00:00');
      expect(output['closed_at'], '2024-01-15 18:00:00');
      expect(output['user'], isA<Map<String, dynamic>>());
    });

    test('fromJson correctly parses nested user with filial', () {
      final json = buildShiftJson(
        user: buildUserJson(
          firstName: 'Alice',
          surname: 'Wonder',
          branch: buildFilialJson(nameRu: 'Центральный'),
        ),
      );
      final shift = Shift.fromJson(json);

      expect(shift.user.firstname, 'Alice');
      expect(shift.user.surname, 'Wonder');
      expect(shift.user.filial, isNotNull);
      expect(shift.user.filial!.name_ru, 'Центральный');
    });
  });
}
