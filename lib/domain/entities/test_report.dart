import 'package:uuid/uuid.dart';

enum TestReportType {
  bloodTest,
  urineTest,
  xray,
  mri,
  ctScan,
  ultrasound,
  ecg,
  pathology,
  other,
}

class TestReport {
  final String id;
  final String filePath;
  final String fileName;
  final String fileType;
  final String reportType;
  final DateTime date;
  final String? testName;
  final String? labName;
  final String? doctorName;
  final String? notes;
  final double? fileSize;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastModified;
  final int version;

  TestReport({
    String? id,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.reportType,
    required this.date,
    this.testName,
    this.labName,
    this.doctorName,
    this.notes,
    this.fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastModified,
    this.version = 1,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       lastModified = lastModified ?? DateTime.now();

  TestReport copyWith({
    String? id,
    String? filePath,
    String? fileName,
    String? fileType,
    String? reportType,
    DateTime? date,
    String? testName,
    String? labName,
    String? doctorName,
    String? notes,
    double? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastModified,
    int? version,
  }) {
    return TestReport(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      reportType: reportType ?? this.reportType,
      date: date ?? this.date,
      testName: testName ?? this.testName,
      labName: labName ?? this.labName,
      doctorName: doctorName ?? this.doctorName,
      notes: notes ?? this.notes,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastModified: lastModified ?? DateTime.now(),
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_path': filePath,
      'file_name': fileName,
      'file_type': fileType,
      'report_type': reportType,
      'date': date.toIso8601String(),
      'test_name': testName,
      'lab_name': labName,
      'doctor_name': doctorName,
      'notes': notes,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_modified': lastModified.toIso8601String(),
      'version': version,
    };
  }

  factory TestReport.fromMap(Map<String, dynamic> map) {
    return TestReport(
      id: map['id'],
      filePath: map['file_path'],
      fileName: map['file_name'],
      fileType: map['file_type'],
      reportType: map['report_type'],
      date: DateTime.parse(map['date']),
      testName: map['test_name'],
      labName: map['lab_name'],
      doctorName: map['doctor_name'],
      notes: map['notes'],
      fileSize: map['file_size'] != null ? (map['file_size'] as num).toDouble() : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      lastModified: map['last_modified'] != null && map['last_modified'].toString().isNotEmpty
          ? DateTime.parse(map['last_modified'])
          : DateTime.now(),
      version: map['version'] ?? 1,
    );
  }

  bool get isImage {
    final lowerType = fileType.toLowerCase();
    return lowerType.contains('jpg') ||
        lowerType.contains('jpeg') ||
        lowerType.contains('png') ||
        lowerType.contains('gif') ||
        lowerType.contains('bmp') ||
        lowerType.contains('webp');
  }

  bool get isPdf {
    return fileType.toLowerCase().contains('pdf');
  }

  String get fileIcon {
    if (isImage) return '📷';
    if (isPdf) return '📄';
    return '📎';
  }

  String get displayType {
    switch (reportType) {
      case 'blood_test':
        return 'Blood Test';
      case 'urine_test':
        return 'Urine Test';
      case 'xray':
        return 'X-Ray';
      case 'mri':
        return 'MRI';
      case 'ct_scan':
        return 'CT Scan';
      case 'ultrasound':
        return 'Ultrasound';
      case 'ecg':
        return 'ECG';
      case 'pathology':
        return 'Pathology';
      default:
        return 'Other';
    }
  }

  String get typeIcon {
    switch (reportType) {
      case 'blood_test':
        return '🩸';
      case 'urine_test':
        return '💧';
      case 'xray':
        return '📷';
      case 'mri':
        return '🏥';
      case 'ct_scan':
        return '🏥';
      case 'ultrasound':
        return '🌊';
      case 'ecg':
        return '❤️';
      case 'pathology':
        return '🔬';
      default:
        return '📄';
    }
  }

  String get displayDate {
    final now = DateTime.now();
    final difference = now.difference(date).abs();

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TestReport &&
        other.id == id &&
        other.filePath == filePath &&
        other.fileName == fileName;
  }

  @override
  int get hashCode {
    return id.hashCode ^ filePath.hashCode ^ fileName.hashCode;
  }

  @override
  String toString() {
    return 'TestReport(id: $id, fileName: $fileName, reportType: $reportType, date: $date)';
  }
}
