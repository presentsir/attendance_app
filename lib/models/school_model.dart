import 'package:cloud_firestore/cloud_firestore.dart';

class School {
  final String name;
  final String address;
  final String district;
  final String state;
  final String region;
  final double pincode;
  final int affNo;
  final String phoneNumber;
  final String email;
  final String principalName;
  final String principalPhone;
  final String principalEmail;

  School({
    required this.name,
    required this.address,
    required this.district,
    required this.state,
    required this.region,
    required this.pincode,
    required this.affNo,
    required this.phoneNumber,
    required this.email,
    required this.principalName,
    required this.principalPhone,
    required this.principalEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'district': district,
      'state': state,
      'region': region,
      'pincode': pincode,
      'aff_no': affNo,
      'phoneNumber': phoneNumber,
      'email': email,
      'principalName': principalName,
      'principalPhone': principalPhone,
      'principalEmail': principalEmail,
    };
  }

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      name: json['name'] ?? 'Unknown',
      address: json['address'] ?? 'Unknown',
      district: json['district'] ?? 'Unknown',
      state: json['state'] ?? 'Unknown',
      region: json['region'] ?? 'Unknown',
      pincode: double.tryParse(json['pincode'].toString()) ?? 0.0,
      affNo: int.tryParse(json['aff_no'].toString()) ?? 0,
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      principalName: json['principalName'] ?? '',
      principalPhone: json['principalPhone'] ?? '',
      principalEmail: json['principalEmail'] ?? '',
    );
  }

  factory School.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return School(
      name: data['name'] ?? 'Unknown',
      address: data['address'] ?? 'Unknown',
      district: data['district'] ?? 'Unknown',
      state: data['state'] ?? 'Unknown',
      region: data['region'] ?? 'Unknown',
      pincode: double.tryParse(data['pincode'].toString()) ?? 0.0,
      affNo: int.tryParse(data['aff_no'].toString()) ?? 0,
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'] ?? '',
      principalName: data['principalName'] ?? '',
      principalPhone: data['principalPhone'] ?? '',
      principalEmail: data['principalEmail'] ?? '',
    );
  }
}
