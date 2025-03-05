import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentData {
  final String rollNumber;
  final String? id;
  final TextEditingController nameController;
  final TextEditingController mobileController;
  String gender = 'Male';
  String familyStructure = 'Nuclear';
  String parentEducation = 'High School';
  String residentialArea = 'Urban';
  String academicTrend = 'Average';
  final TextEditingController lastYearGradeController;
  final TextEditingController familyIncomeController;

  StudentData({
    required this.rollNumber,
    this.id,
    required this.nameController,
    required this.mobileController,
    TextEditingController? lastYearGradeController,
    TextEditingController? familyIncomeController,
  })  : lastYearGradeController =
            lastYearGradeController ?? TextEditingController(),
        familyIncomeController =
            familyIncomeController ?? TextEditingController();
}

class BulkStudentUpload extends StatefulWidget {
  final String classId;

  BulkStudentUpload({required this.classId});

  @override
  _BulkStudentUploadState createState() => _BulkStudentUploadState();
}

class _BulkStudentUploadState extends State<BulkStudentUpload> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _startRollController = TextEditingController();
  final TextEditingController _endRollController = TextEditingController();
  final List<StudentData> _students = [];
  bool _isLoading = true;
  final Set<String> _existingRollNumbers = {};
  int _selectedIndex = -1;

  final List<String> genderOptions = ['Male', 'Female', 'Prefer not to say'];
  final List<String> familyStructureOptions = [
    'Nuclear',
    'Joint',
    'Single Parent',
    'NGO Support',
    'Orphan'
  ];
  final List<String> parentEducationOptions = [
    'High School',
    'Graduate',
    'Post Graduate',
    'Others',
    'None'
  ];
  final List<String> residentialAreaOptions = ['Urban', 'Rural'];
  final List<String> academicTrendOptions = ['Good', 'Average', 'Poor'];

  @override
  void initState() {
    super.initState();
    _loadExistingStudents();
  }

  Future<void> _loadExistingStudents() async {
    setState(() => _isLoading = true);
    try {
      final QuerySnapshot studentsSnapshot = await _firestore
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .orderBy('rollNumber')
          .get();

      _students.clear();
      _existingRollNumbers.clear();

      for (var doc in studentsSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        var student = StudentData(
          id: doc.id,
          rollNumber: data['rollNumber'],
          nameController: TextEditingController(text: data['name']),
          mobileController: TextEditingController(text: data['mobileNumber']),
          lastYearGradeController: TextEditingController(
              text: data['lastYearGrade']?.toString() ?? ''),
          familyIncomeController: TextEditingController(
              text: data['familyIncome']?.toString() ?? ''),
        );
        student.gender = data['gender'] ?? 'Male';
        student.familyStructure = data['familyStructure'] ?? 'Nuclear';
        student.parentEducation = data['parentEducation'] ?? 'High School';
        student.residentialArea = data['residentialArea'] ?? 'Urban';
        student.academicTrend = data['academicTrend'] ?? 'Average';

        _students.add(student);
        _existingRollNumbers.add(data['rollNumber']);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading students: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStudentCard(StudentData student, int index) {
    bool isSelected = _selectedIndex == index;

    return Card(
      elevation: isSelected ? 4 : 1,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          setState(() {
            _selectedIndex = expanded ? index : -1;
          });
        },
        title: Row(
          children: [
            CircleAvatar(
              child: Text(student.rollNumber),
              backgroundColor: Colors.blue[100],
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: student.nameController,
                decoration: InputDecoration(
                  labelText: 'Student Name',
                  border: UnderlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contact Information
                Text('Contact Information',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                TextField(
                  controller: student.mobileController,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16),

                // Personal Information
                Text('Personal Information',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isNarrow = constraints.maxWidth < 400;
                    return Column(
                      children: [
                        if (isNarrow) ...[
                          DropdownButtonFormField<String>(
                            value: student.gender,
                            decoration: InputDecoration(
                              labelText: 'Gender',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            items: genderOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                student.gender = value!;
                              });
                            },
                          ),
                          SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: student.residentialArea,
                            decoration: InputDecoration(
                              labelText: 'Residential Area',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            items: residentialAreaOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                student.residentialArea = value!;
                              });
                            },
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: student.gender,
                                  decoration: InputDecoration(
                                    labelText: 'Gender',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  items: genderOptions.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      student.gender = value!;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: student.residentialArea,
                                  decoration: InputDecoration(
                                    labelText: 'Residential Area',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  items: residentialAreaOptions
                                      .map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      student.residentialArea = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 16),

                // Family Information
                Text('Family Information',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: student.familyStructure,
                  decoration: InputDecoration(
                    labelText: 'Family Structure',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  items: familyStructureOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      student.familyStructure = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isNarrow = constraints.maxWidth < 400;
                    return Column(
                      children: [
                        if (isNarrow) ...[
                          DropdownButtonFormField<String>(
                            value: student.parentEducation,
                            decoration: InputDecoration(
                              labelText: 'Parent Education',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            items: parentEducationOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                student.parentEducation = value!;
                              });
                            },
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: student.familyIncomeController,
                            decoration: InputDecoration(
                              labelText: 'Family Income (INR/Year)',
                              border: OutlineInputBorder(),
                              prefixText: '₹ ',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: student.parentEducation,
                                  decoration: InputDecoration(
                                    labelText: 'Parent Education',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  items: parentEducationOptions
                                      .map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      student.parentEducation = value!;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: student.familyIncomeController,
                                  decoration: InputDecoration(
                                    labelText: 'Family Income (INR/Year)',
                                    border: OutlineInputBorder(),
                                    prefixText: '₹ ',
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 16),

                // Academic Information
                Text('Academic Information',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isNarrow = constraints.maxWidth < 400;
                    return Column(
                      children: [
                        if (isNarrow) ...[
                          DropdownButtonFormField<String>(
                            value: student.academicTrend,
                            decoration: InputDecoration(
                              labelText: 'Academic Trend',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            items: academicTrendOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                student.academicTrend = value!;
                              });
                            },
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: student.lastYearGradeController,
                            decoration: InputDecoration(
                              labelText: 'Last Year Grade (%)',
                              border: OutlineInputBorder(),
                              suffixText: '%',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: student.academicTrend,
                                  decoration: InputDecoration(
                                    labelText: 'Academic Trend',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  items:
                                      academicTrendOptions.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      student.academicTrend = value!;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: student.lastYearGradeController,
                                  decoration: InputDecoration(
                                    labelText: 'Last Year Grade (%)',
                                    border: OutlineInputBorder(),
                                    suffixText: '%',
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Management'),
        actions: [
          if (_students.isNotEmpty)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _showAddNewStudentDialog(),
              tooltip: 'Add New Student',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_students.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Add Multiple Students',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _startRollController,
                                    decoration: InputDecoration(
                                      labelText: 'Start Roll Number',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                  //
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: _endRollController,
                                    decoration: InputDecoration(
                                      labelText: 'End Roll Number',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _generateStudentList,
                              icon: Icon(Icons.group_add),
                              label: Text('Generate Student List'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: ListView.builder(
                    itemCount: _students.length,
                    itemBuilder: (context, index) =>
                        _buildStudentCard(_students[index], index),
                  ),
                ),
                if (_students.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: _saveStudents,
                      icon: Icon(Icons.save),
                      label: Text('Save All Students'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  void _generateStudentList() {
    int startRoll = int.tryParse(_startRollController.text) ?? 0;
    int endRoll = int.tryParse(_endRollController.text) ?? 0;

    if (startRoll <= 0 || endRoll <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid roll numbers')),
      );
      return;
    }

    if (startRoll > endRoll) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Start roll number must be less than end roll number')),
      );
      return;
    }

    // Check for duplicate roll numbers
    Set<String> newRollNumbers = {};
    for (int i = startRoll; i <= endRoll; i++) {
      if (_existingRollNumbers.contains(i.toString()) ||
          newRollNumbers.contains(i.toString())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Roll number $i already exists')),
        );
        return;
      }
      newRollNumbers.add(i.toString());
    }

    setState(() {
      for (int i = startRoll; i <= endRoll; i++) {
        _students.add(StudentData(
          rollNumber: i.toString(),
          nameController: TextEditingController(),
          mobileController: TextEditingController(),
        ));
      }
      _students.sort(
          (a, b) => int.parse(a.rollNumber).compareTo(int.parse(b.rollNumber)));
    });
  }

  Future<void> _showAddNewStudentDialog() async {
    // Find the highest roll number
    int highestRoll = _students.isEmpty
        ? 0
        : _students
            .map((s) => int.tryParse(s.rollNumber) ?? 0)
            .reduce((a, b) => a > b ? a : b);

    String newRollNumber = (highestRoll + 1).toString();

    setState(() {
      _students.add(StudentData(
        rollNumber: newRollNumber,
        nameController: TextEditingController(),
        mobileController: TextEditingController(),
      ));
      _students.sort(
          (a, b) => int.parse(a.rollNumber).compareTo(int.parse(b.rollNumber)));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('New student added with roll number $newRollNumber')),
    );
  }

  Future<void> _saveStudents() async {
    try {
      // Validation
      for (var student in _students) {
        if (student.nameController.text.isEmpty ||
            student.mobileController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Please fill name and mobile number for roll number ${student.rollNumber}')),
          );
          return;
        }

        // Validate percentage
        double? percentage =
            double.tryParse(student.lastYearGradeController.text);
        if (student.lastYearGradeController.text.isNotEmpty &&
            (percentage == null || percentage < 0 || percentage > 100)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Invalid percentage for roll number ${student.rollNumber}')),
          );
          return;
        }

        // Validate family income
        if (student.familyIncomeController.text.isNotEmpty &&
            double.tryParse(student.familyIncomeController.text) == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Invalid family income for roll number ${student.rollNumber}')),
          );
          return;
        }
      }

      WriteBatch batch = _firestore.batch();

      for (var student in _students) {
        DocumentReference docRef;
        if (student.id != null) {
          docRef = _firestore
              .collection('classes')
              .doc(widget.classId)
              .collection('students')
              .doc(student.id);
        } else {
          docRef = _firestore
              .collection('classes')
              .doc(widget.classId)
              .collection('students')
              .doc();
        }

        batch.set(docRef, {
          'rollNumber': student.rollNumber,
          'name': student.nameController.text,
          'mobileNumber': student.mobileController.text,
          'gender': student.gender,
          'familyStructure': student.familyStructure,
          'parentEducation': student.parentEducation,
          'residentialArea': student.residentialArea,
          'academicTrend': student.academicTrend,
          'lastYearGrade': student.lastYearGradeController.text.isNotEmpty
              ? double.parse(student.lastYearGradeController.text)
              : null,
          'familyIncome': student.familyIncomeController.text.isNotEmpty
              ? double.parse(student.familyIncomeController.text)
              : null,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Students data saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving students: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    for (var student in _students) {
      student.nameController.dispose();
      student.mobileController.dispose();
      student.lastYearGradeController.dispose();
      student.familyIncomeController.dispose();
    }
    _startRollController.dispose();
    _endRollController.dispose();
    super.dispose();
  }
}
