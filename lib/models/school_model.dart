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
      name: json['name'],
      affNo: json['aff_no'],
      state: json['state'],
      district: json['district'],
      region: json['region'],
      address: json['address'],
      pincode: json['pincode'],
    );
  }
}