import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getCollection(String name) async {
    try {
      final snapshot = await _firestore.collection(name).get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      debugPrint('Error fetching collection $name: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCollectionWithLimit(
    String name, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore.collection(name).limit(limit).get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      debugPrint('Error fetching collection $name with limit: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String id,
  ) async {
    try {
      final doc = await _firestore.collection(collection).doc(id).get();
      if (doc.exists) {
        return {...doc.data() ?? {}, 'id': doc.id};
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching document from $collection: $e');
      return null;
    }
  }

  Future<void> addDocument(String collection, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).add(data);
    } catch (e) {
      debugPrint('Error adding document to $collection: $e');
    }
  }

  Future<void> updateDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collection).doc(id).update(data);
    } catch (e) {
      debugPrint('Error updating document in $collection: $e');
    }
  }

  Future<void> deleteDocument(String collection, String id) async {
    try {
      await _firestore.collection(collection).doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting document from $collection: $e');
    }
  }

  Future<List<Map<String, dynamic>>> queryCollection(
    String collection, {
    required String field,
    required dynamic value,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .where(field, isEqualTo: value)
          .get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      debugPrint('Error querying $collection: $e');
      return [];
    }
  }
}
