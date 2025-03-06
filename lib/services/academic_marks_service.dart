import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicMarksService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new test result
  Future<void> addTestResult({
    required String classId,
    required String subject,
    required DateTime testDate,
    required String testName,
    required List<Map<String, dynamic>> studentMarks,
    required String teacherId,
  }) async {
    try {
      await _firestore.collection('academic_marks').add({
        'classId': classId,
        'subject': subject,
        'testDate': Timestamp.fromDate(testDate),
        'testName': testName,
        'studentMarks': studentMarks,
        'teacherId': teacherId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding test result: $e');
      rethrow;
    }
  }

  // Get test results for a class
  Stream<QuerySnapshot> getTestResults({
    required String classId,
    String? subject,
  }) {
    Query query = _firestore
        .collection('academic_marks')
        .where('classId', isEqualTo: classId)
        .orderBy('testDate', descending: true);

    if (subject != null) {
      query = query.where('subject', isEqualTo: subject);
    }

    return query.snapshots();
  }

  // Get test results for a specific student
  Stream<QuerySnapshot> getStudentTestResults({
    required String classId,
    required String studentId,
    String? subject,
  }) {
    Query query = _firestore
        .collection('academic_marks')
        .where('classId', isEqualTo: classId)
        .where('studentMarks', arrayContains: {'studentId': studentId}).orderBy(
            'testDate',
            descending: true);

    if (subject != null) {
      query = query.where('subject', isEqualTo: subject);
    }

    return query.snapshots();
  }

  // Update a test result
  Future<void> updateTestResult({
    required String testId,
    required List<Map<String, dynamic>> studentMarks,
  }) async {
    try {
      await _firestore.collection('academic_marks').doc(testId).update({
        'studentMarks': studentMarks,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating test result: $e');
      rethrow;
    }
  }

  // Delete a test result
  Future<void> deleteTestResult(String testId) async {
    try {
      await _firestore.collection('academic_marks').doc(testId).delete();
    } catch (e) {
      print('Error deleting test result: $e');
      rethrow;
    }
  }
}
