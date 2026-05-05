import 'package:uuid/uuid.dart';

class Prescription {
  final String id;
  final String filePath;
  final String fileName;
  final String fileType;
  final DateTime date;
  final String? notes;
  final String? doctorName;
  final String? clinicName;
  final double? fileSize; // in KB
  final DateTime createdAt;
  final DateTime updatedAt;

  Prescription({
    String? id,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.date,
    this.notes,
    this.doctorName,
    this.clinicName,
    this.fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Create a copy of prescription with updated fields
  Prescription copyWith({
    String? id,
    String? filePath,
    String? fileName,
    String? fileType,
    DateTime? date,
    String? notes,
    String? doctorName,
    String? clinicName,
    double? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Prescription(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      doctorName: doctorName ?? this.doctorName,
      clinicName: clinicName ?? this.clinicName,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_path': filePath,
      'file_name': fileName,
      'file_type': fileType,
      'date': date.toIso8601String(),
      'notes': notes,
      'doctor_name': doctorName,
      'clinic_name': clinicName,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from map (from database)
  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'],
      filePath: map['file_path'],
      fileName: map['file_name'],
      fileType: map['file_type'],
      date: DateTime.parse(map['date']),
      notes: map['notes'],
      doctorName: map['doctor_name'],
      clinicName: map['clinic_name'],
      fileSize: map['file_size'] != null ? (map['file_size'] as num).toDouble() : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // Check if prescription is an image
  bool get isImage {
    final lowerType = fileType.toLowerCase();
    return lowerType.contains('jpg') ||
        lowerType.contains('jpeg') ||
        lowerType.contains('png') ||
        lowerType.contains('gif') ||
        lowerType.contains('bmp') ||
        lowerType.contains('webp');
  }

  // Check if prescription is a PDF
  bool get isPdf {
    return fileType.toLowerCase().contains('pdf');
  }

  // Check if prescription is a document
  bool get isDocument {
    final lowerType = fileType.toLowerCase();
    return lowerType.contains('doc') ||
        lowerType.contains('docx') ||
        lowerType.contains('txt') ||
        lowerType.contains('rtf');
  }

  // Get file icon based on type
  String get fileIcon {
    if (isImage) return '📷';
    if (isPdf) return '📄';
    if (isDocument) return '📝';
    return '📎';
  }

  // Get display date in readable format
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
    
    return other is Prescription &&
        other.id == id &&
        other.filePath == filePath &&
        other.fileName == fileName &&
        other.fileType == fileType &&
        other.date == date &&
        other.notes == notes &&
        other.doctorName == doctorName &&
        other.clinicName == clinicName &&
        other.fileSize == fileSize;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        filePath.hashCode ^
        fileName.hashCode ^
        fileType.hashCode ^
        date.hashCode ^
        notes.hashCode ^
        doctorName.hashCode ^
        clinicName.hashCode ^
        fileSize.hashCode;
  }

  @override
  String toString() {
    return 'Prescription(id: $id, fileName: $fileName, fileType: $fileType, date: $date, doctorName: $doctorName)';
  }
}
