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
   void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _saveChanges();
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBase64 = base64Encode(bytes);
          isBase64 = true;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }
  Widget _getImageWidget() {
    if (_selectedImageBase64 != null && _selectedImageBase64!.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(_selectedImageBase64!),
          width: double.infinity,
          fit: BoxFit.cover,
          height: 300,
        );
      } catch (e) {
        print('Error decoding image: $e');
      }
    } else if (isBase64) {
      return Image.memory(
        base64Decode(photo),
        width: double.infinity,
        fit: BoxFit.cover,
        height: 300,
      );
    }

    return Image.network(
      photo,
      width: double.infinity,
      fit: BoxFit.cover,
      height: 300,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 300,
        color: CupertinoColors.systemGrey.withOpacity(0.2),
        child: Icon(CupertinoIcons.person_crop_circle_fill, size: 100, color: CupertinoColors.systemGrey),
      ),
    );
  }

  void _saveChanges() {
    name = _nameController.text;
    email = _emailController.text;
    url = _urlController.text;

    if (_selectedImageBase64 != null) {
      photo = _selectedImageBase64!;
      isBase64 = true;
    }
 if (_phoneNumbersEditing.isNotEmpty) {
      phoneNumbers = List<Map<String, dynamic>>.from(_phoneNumbersEditing);
      phone = _phoneNumbersEditing[0]['number'] ?? '';
    }

    if (_contactIndex != null) {
      List<dynamic> contacts = _myBox.get('contacts') ?? [];
      contacts[_contactIndex!] = {
        "name": name,
        "company": contacts[_contactIndex!]['company'] ?? '',
        "phone": phone,
        "phoneNumbers": phoneNumbers,
        "email": email,
        "url": url,
        "photo": photo,
        "isBase64": isBase64,
      };
      _myBox.put('contacts', contacts);
    }
  }
 void _addPhoneNumber() {
    setState(() {
      _phoneNumbersEditing.add({'label': 'mobile', 'number': ''});
    });
  }

  void _removePhoneNumber(int index) {
    setState(() {
      _phoneNumbersEditing.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Header Image
                  _getImageWidget(),

                  // Back Button
                  Positioned(
                    top: 10,
                    left: 10,
                    child: CupertinoButton(
                      padding: EdgeInsets.all(12),
                      borderRadius: BorderRadius.circular(20),
                      color: CupertinoColors.systemGrey.withOpacity(0.4),
                      child: Icon(CupertinoIcons.chevron_back, size: 20, color: CupertinoColors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Edit/Save Button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: CupertinoButton(
                      padding: EdgeInsets.all(12),
                      borderRadius: BorderRadius.circular(20),
                      color: CupertinoColors.systemGrey.withOpacity(0.4),
                      child: Icon(
                        _isEditing ? CupertinoIcons.checkmark_alt : CupertinoIcons.pencil,
                        size: 20,
                        color: CupertinoColors.white,
                      ),
                      onPressed: _toggleEditMode,
                    ),
                  ),

                  // Change Photo Button (only in edit mode)
                  if (_isEditing)
                    Positioned(
                      top: 60,
                      right: 10,
                      child: CupertinoButton(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        borderRadius: BorderRadius.circular(20),
                        color: CupertinoColors.systemGrey.withOpacity(0.6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.photo, size: 16, color: CupertinoColors.white),
                            SizedBox(width: 5),
                            Text("Change Photo", style: TextStyle(fontSize: 14, color: CupertinoColors.white)),
                          ],
                        ),
                        onPressed: _pickImage,
                      ),
                    ),
 // Name and Action Buttons
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        // Last Used indicator
                        if (!_isEditing) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("last used: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: CupertinoColors.white)),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: CupertinoColors.white.withOpacity(0.9),
                                  ),
                                  child: Text("P", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CupertinoColors.black)),
                                ),
                                SizedBox(width: 4),
                                Text("Primary", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: CupertinoColors.white)),
                                Icon(CupertinoIcons.chevron_forward, size: 12, color: CupertinoColors.white),
                              ],
                            ),
                          ),
                        ],

                        // Name Field
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _isEditing
                              ? CupertinoTextField(
                            controller: _nameController,
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: CupertinoColors.white),
                            placeholder: 'Name',
                            placeholderStyle: TextStyle(color: CupertinoColors.white.withOpacity(0.7)),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          )
                              : Text(
                            name,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

