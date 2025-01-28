class School {
  final String name;
  final String address;
  final String district;
  final String state;
  final int affNo;

  School({
    required this.name,
    required this.address,
    required this.district,
    required this.state,
    required this.affNo,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'district': district,
      'state': state,
      'affNo': affNo,
    };
  }

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      name: json['name'] as String,
      address: json['address'] as String,
      district: json['district'] as String,
      state: json['state'] as String,
      affNo: json['affNo'] as int,
    );
  }
}