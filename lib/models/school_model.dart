class School {
  final String name;
  final int affNo;
  final String state;
  final String district;
  final String region;
  final String address;
  final double pincode;

  School({
    required this.name,
    required this.affNo,
    required this.state,
    required this.district,
    required this.region,
    required this.address,
    required this.pincode,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      name: json['name'] ?? 'Unknown',
      affNo: json['aff_no'] ?? 0,
      state: json['state'] ?? 'Unknown',
      district: json['district'] ?? 'Unknown',
      region: json['region'] ?? 'Unknown',
      address: json['address'] ?? 'Unknown',
      pincode: double.tryParse(json['pincode'].toString()) ?? 0.0, // Handle both String and double
    );
  }
}