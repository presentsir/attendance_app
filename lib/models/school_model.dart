class School {
  final String name;
  final String address;
  final String district;
  final String state;
  final String region;
  final double pincode;
  final int affNo;

  School({
    required this.name,
    required this.address,
    required this.district,
    required this.state,
    required this.region,
    required this.pincode,
    required this.affNo,
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
    );
  }
}