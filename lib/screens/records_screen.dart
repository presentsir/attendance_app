import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecordsScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Records'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('attendance').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var record = snapshot.data!.docs[index];
              return ListTile(
                title: Text('Student: ${record['studentId']}'),
                subtitle: Text('Date: ${record['date']}, Status: ${record['status']}'),
              );
            },
          );
        },
      ),
    );
  }
}