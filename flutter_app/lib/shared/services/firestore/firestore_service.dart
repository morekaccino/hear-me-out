import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final String collectionName;
  final CollectionReference _collection;

  FirestoreService(this.collectionName)
      : _collection = FirebaseFirestore.instance.collection(collectionName);

  Future<void> createDocument(String docId, Map<String, dynamic> data, {bool merge = true}) async {
    data['updated_at'] = FieldValue.serverTimestamp();
    await _collection.doc(docId).set(data, SetOptions(merge: merge));
  }

  Future<DocumentSnapshot> getDocument(String docId) async {
    return _collection.doc(docId).get();
  }

  Future<void> updateDocument(String docId, Map<String, dynamic> data) async {
    data['updated_at'] = FieldValue.serverTimestamp();
    await _collection.doc(docId).update(data);
  }

  Future<bool> documentExists(String docId) async {
    final doc = await _collection.doc(docId).get();
    return doc.exists;
  }
}
