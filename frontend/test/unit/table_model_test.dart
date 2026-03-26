import 'package:test/test.dart';
import 'package:frontend/models/table_model.dart';

void main() {
  final tableAsJson = '{"id":7}';
  final tableListAsJson = '[{"id":7},{"id":8}]';

  final table = TableModel(id: 7);

  test('Convert Table from json', () {
    final tableFromSampleJson = tableFromJson(tableAsJson);
    expect(tableFromSampleJson == table, true);

    final tablesFromSampleJson = tableListFromJson(tableListAsJson);
    expect(tablesFromSampleJson.contains(table), true);
    expect(tablesFromSampleJson.length == 2, true);
  });

  test('Convert Table to json (roundtrip)', () {
    final jsonStr = tableToJson(table);
    final roundTrip = tableFromJson(jsonStr);

    expect(roundTrip == table, true);
  });

  test('Table == uses identical fast-path and hashCode is consistent', () {
    // identical fast-path
    final sameRef = table;
    expect(identical(table, sameRef), true);
    expect(table == sameRef, true);
    expect(table.hashCode == sameRef.hashCode, true);

    // Different instance, same values: identical false, == true, hashCode should match
    final copy = TableModel(id: table.id);

    expect(identical(table, copy), false);
    expect(table == copy, true);
    expect(table.hashCode == copy.hashCode, true);

    // Different values: == false, and hashCode should (very likely) differ
    final different = TableModel(id: table.id + 1);

    expect(table == different, false);

    // Note: hashCode collisions are possible in theory, so we don't assert "!=" strictly here.
  });

  test('TableModel.fromJson throws if id is missing (optional)', () {
    expect(() => TableModel.fromJson({}), throwsA(isA<TypeError>()));
    // Je nach Dart-Version/Runtime kann auch ein anderes Error-Subtype kommen.
    // Falls das bei dir flakey ist, ersetze durch:
    // expect(() => TableModel.fromJson({}), throwsA(anything));
  });
}
