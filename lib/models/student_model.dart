class StudentModel {
  final String id;
  final String name;
  final String rollNumber;
  final String educationBoard;
  final String gender;
  final String familyStructure;
  final String parentEducation;
  final String residentialArea;
  final double lastYearMarks;
  final double familyIncome;

  StudentModel({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.educationBoard,
    required this.gender,
    required this.familyStructure,
    required this.parentEducation,
    required this.residentialArea,
    required this.lastYearMarks,
    required this.familyIncome,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rollNumber': rollNumber,
      'educationBoard': educationBoard,
      'gender': gender,
      'familyStructure': familyStructure,
      'parentEducation': parentEducation,
      'residentialArea': residentialArea,
      'lastYearMarks': lastYearMarks,
      'familyIncome': familyIncome,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      educationBoard: map['educationBoard'] ?? 'CBSE',
      gender: map['gender'] ?? 'male',
      familyStructure: map['familyStructure'] ?? 'nuclear',
      parentEducation: map['parentEducation'] ?? 'high school',
      residentialArea: map['residentialArea'] ?? 'urban',
      lastYearMarks: (map['lastYearMarks'] ?? 0.0).toDouble(),
      familyIncome: (map['familyIncome'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toDropoutAnalysisData() {
    return {
      'education_board': educationBoard,
      'gender': gender,
      'family_structure': familyStructure,
      'parent_education': parentEducation,
      'residential_area': residentialArea,
      'last_year_marks': lastYearMarks,
      'family_income': familyIncome,
    };
  }
}
