import 'package:champions_ring_app/core/utils/base_repository.dart';
import 'package:champions_ring_app/core/utils/firestore_entity.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestEntity extends FirestoreEntity {
  @override
  final String uid;
  final String creationDate;
  final String name;

  const _TestEntity({
    required this.uid,
    required this.creationDate,
    required this.name,
  });

  @override
  Map<String, dynamic> toFirebaseMap() => {
    'uid': uid,
    'creationDate': creationDate,
    'name': name,
  };
}

class _TestRepository extends BaseRepository<_TestEntity> {
  @override
  String get collectionName => 'test';

  Map<String, dynamic> buildData(
    _TestEntity entity,
    Map<String, dynamic>? existingData,
  ) => dataForUpsert(entity, existingData);

  @override
  Future<_TestEntity> getById(String uid) => throw UnimplementedError();
}

void main() {
  test('updating an entity preserves uid and creation date', () {
    const updatedEntity = _TestEntity(
      uid: 'new-uid',
      creationDate: 'new-date',
      name: 'Updated name',
    );
    final repository = _TestRepository();

    final data = repository.buildData(updatedEntity, {
      'uid': 'original-uid',
      'creationDate': 'original-date',
      'name': 'Original name',
    });

    expect(data, {
      'uid': 'original-uid',
      'creationDate': 'original-date',
      'name': 'Updated name',
    });
  });
}
