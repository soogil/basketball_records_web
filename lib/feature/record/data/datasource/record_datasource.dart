import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iggys_point/core/api/firestore_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'record_datasource.g.dart';

abstract class RecordDataSource {
  Future<bool> hasAnyRealRecordOnDate(String date);
}

class RecordDataSourceImpl implements RecordDataSource {
  RecordDataSourceImpl(this._fireStoreApi);

  final FireStoreApi _fireStoreApi;

  @override
  Future<bool> hasAnyRealRecordOnDate(String date) async {
    return await _fireStoreApi.hasAnyRealRecordOnDate(date);
  }

}

@riverpod
RecordDataSource recordDataSource(Ref ref) {
  final api = ref.watch(fireStoreApiProvider);
  return RecordDataSourceImpl(api);
}