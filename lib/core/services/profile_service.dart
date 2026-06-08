import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfileCustomField {
  const ProfileCustomField({required this.label, required this.value});

  final String label;
  final String value;

  ProfileCustomField copyWith({String? label, String? value}) {
    return ProfileCustomField(
      label: label ?? this.label,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'value': value,
  };

  factory ProfileCustomField.fromJson(Map<String, dynamic> json) {
    return ProfileCustomField(
      label: (json['label'] ?? '') as String,
      value: (json['value'] ?? '') as String,
    );
  }
}

class ProfileData {
  const ProfileData({
    this.fullName = '',
    this.age = '',
    this.heightCm = '',
    this.weightKg = '',
    this.bloodGroup = '',
    this.gender = '',
    this.emergencyContact = '',
    this.notes = '',
    this.customFields = const [],
  });

  final String fullName;
  final String age;
  final String heightCm;
  final String weightKg;
  final String bloodGroup;
  final String gender;
  final String emergencyContact;
  final String notes;
  final List<ProfileCustomField> customFields;

  static const empty = ProfileData();

  ProfileData copyWith({
    String? fullName,
    String? age,
    String? heightCm,
    String? weightKg,
    String? bloodGroup,
    String? gender,
    String? emergencyContact,
    String? notes,
    List<ProfileCustomField>? customFields,
  }) {
    return ProfileData(
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      gender: gender ?? this.gender,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      notes: notes ?? this.notes,
      customFields: customFields ?? this.customFields,
    );
  }

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'age': age,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'bloodGroup': bloodGroup,
    'gender': gender,
    'emergencyContact': emergencyContact,
    'notes': notes,
    'customFields': customFields.map((field) => field.toJson()).toList(),
  };

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    final rawCustomFields = json['customFields'];
    return ProfileData(
      fullName: (json['fullName'] ?? '') as String,
      age: (json['age'] ?? '') as String,
      heightCm: (json['heightCm'] ?? '') as String,
      weightKg: (json['weightKg'] ?? '') as String,
      bloodGroup: (json['bloodGroup'] ?? '') as String,
      gender: (json['gender'] ?? '') as String,
      emergencyContact: (json['emergencyContact'] ?? '') as String,
      notes: (json['notes'] ?? '') as String,
      customFields: rawCustomFields is List
          ? rawCustomFields
                .whereType<Map>()
                .map(
                  (item) => ProfileCustomField.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class ProfileService {
  ProfileService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _profileStorageKey = 'user_profile_data';

  final FlutterSecureStorage _secureStorage;

  Future<ProfileData> getProfile() async {
    final jsonString = await _secureStorage.read(key: _profileStorageKey);
    if (jsonString == null || jsonString.trim().isEmpty) {
      return ProfileData.empty;
    }

    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return ProfileData.fromJson(decoded);
    } catch (_) {
      return ProfileData.empty;
    }
  }

  Future<void> saveProfile(ProfileData profile) async {
    await _secureStorage.write(
      key: _profileStorageKey,
      value: jsonEncode(profile.toJson()),
    );
  }

  Future<void> clearProfile() async {
    await _secureStorage.delete(key: _profileStorageKey);
  }
}
