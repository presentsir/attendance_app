import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addStudent(String name, String rollNo) async {
    try {
      await _firestore.collection('students').add({
        'name': name,
        'rollNo': rollNo,
      });
    } catch (e) {
      print('Failed to add student: $e');
      // Optionally, you can rethrow the error or handle it in a way that suits your application
      rethrow;
    }
  }
}