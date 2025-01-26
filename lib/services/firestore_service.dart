import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addStudent(String name, String rollNo) async {
    await _firestore.collection('students').add({
      'name': name,
      'rollNo': rollNo,
    });
  }
}