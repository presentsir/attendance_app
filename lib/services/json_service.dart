import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/school_model.dart';

class JsonService {
  Future<List<School>> loadSchools() async {
    try {
      final String response = await rootBundle.loadString('assets/data/SchoolCBSE.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => School.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}