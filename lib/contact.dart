import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'variables.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive_flutter/adapters.dart';

class Contact extends StatefulWidget {
  const Contact({super.key});

  @override
  State<Contact> createState() => _ContactState();
}

class _ContactState extends State<Contact> {
  bool _isEditing = false;
  late Box<dynamic> _myBox;
  int? _contactIndex;
  final ImagePicker _picker = ImagePicker();
  String? _selectedImageBase64;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _urlController;
  List<Map<String, dynamic>> _phoneNumbersEditing = [];

  @override
  void initState() {
    super.initState();
    _myBox = Hive.box('database');
    _nameController = TextEditingController(text: name);
    _emailController = TextEditingController(text: email);
    _urlController = TextEditingController(text: url);

    if (isBase64) {
      _selectedImageBase64 = photo;
    }
 _findContactIndex();

    if (phoneNumbers.isNotEmpty) {
      _phoneNumbersEditing = List<Map<String, dynamic>>.from(phoneNumbers);
    } else if (phone.isNotEmpty) {
      _phoneNumbersEditing = [{'label': 'mobile', 'number': phone}];
    }
  }

  void _findContactIndex() {
    List<dynamic> contacts = _myBox.get('contacts') ?? [];
    for (int i = 0; i < contacts.length; i++) {
      if (contacts[i]['name'] == name && contacts[i]['email'] == email) {
        _contactIndex = i;
        break;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _urlController.dispose();
    super.dispose();
  }