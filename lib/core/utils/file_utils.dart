import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FileUtils {
  // Get application documents directory
  static Future<Directory> get appDocumentsDirectory async {
    return await getApplicationDocumentsDirectory();
  }
  
  // Get application support directory
  static Future<Directory> get appSupportDirectory async {
    return await getApplicationSupportDirectory();
  }
  
  // Get temporary directory
  static Future<Directory> get tempDirectory async {
    return await getTemporaryDirectory();
  }
  
  // Create directory if it doesn't exist
  static Future<Directory> createDirectory(String dirPath) async {
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
  
  // Get prescriptions directory
  static Future<Directory> get prescriptionsDirectory async {
    final appDir = await appDocumentsDirectory;
    final prescriptionsDir = Directory(path.join(appDir.path, 'prescriptions'));
    return await createDirectory(prescriptionsDir.path);
  }
  
  // Get reports directory
  static Future<Directory> get reportsDirectory async {
    final appDir = await appDocumentsDirectory;
    final reportsDir = Directory(path.join(appDir.path, 'reports'));
    return await createDirectory(reportsDir.path);
  }
  
  // Get images directory
  static Future<Directory> get imagesDirectory async {
    final appDir = await appDocumentsDirectory;
    final imagesDir = Directory(path.join(appDir.path, 'images'));
    return await createDirectory(imagesDir.path);
  }
  
  // Save file to app directory
  static Future<File> saveFile(File sourceFile, String destinationPath) async {
    // Create parent directory if it doesn't exist
    final parentDir = Directory(path.dirname(destinationPath));
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }
    
    // Copy file
    return await sourceFile.copy(destinationPath);
  }
  
  // Generate unique filename
  static String generateUniqueFilename(String originalFilename, {String? prefix}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(originalFilename);
    final basename = path.basenameWithoutExtension(originalFilename);
    
    final uniqueName = '${prefix ?? ''}${prefix != null ? '_' : ''}${basename}_$timestamp$extension';
    return uniqueName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
  }
  
  // Get file size in human-readable format
  static String getFileSize(File file) {
    final sizeInBytes = file.lengthSync();
    
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
  
  // Get file extension
  static String getFileExtension(String filename) {
    return path.extension(filename).toLowerCase();
  }
  
  // Check if file is an image
  static bool isImageFile(String filename) {
    final extension = getFileExtension(filename);
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension);
  }
  
  // Check if file is a PDF
  static bool isPdfFile(String filename) {
    final extension = getFileExtension(filename);
    return extension == '.pdf';
  }
  
  // Check if file is a document
  static bool isDocumentFile(String filename) {
    final extension = getFileExtension(filename);
    return ['.doc', '.docx', '.txt', '.rtf'].contains(extension);
  }
  
  // Get file icon based on type
  static String getFileIcon(String filename) {
    if (isImageFile(filename)) return '📷';
    if (isPdfFile(filename)) return '📄';
    if (isDocumentFile(filename)) return '📝';
    return '📎';
  }
  
  // Delete file
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Check if file exists
  static Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }
  
  // Get file creation date
  static Future<DateTime?> getFileCreationDate(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.modified;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Save prescription file to app directory
  static Future<Map<String, dynamic>> savePrescriptionFile(File sourceFile) async {
    try {
      final prescriptionsDir = await prescriptionsDirectory;
      final originalName = path.basename(sourceFile.path);
      final fileExtension = path.extension(originalName);
      final uniqueName = 'prescription_${const Uuid().v4()}$fileExtension';
      final destinationPath = path.join(prescriptionsDir.path, uniqueName);
      
      // Save file
      final savedFile = await saveFile(sourceFile, destinationPath);
      
      // Get file info
      final fileSize = savedFile.lengthSync() / 1024; // KB
      final fileType = getFileType(fileExtension);
      
      return {
        'file': savedFile,
        'path': savedFile.path,
        'name': originalName,
        'uniqueName': uniqueName,
        'type': fileType,
        'size': fileSize,
        'extension': fileExtension,
      };
    } catch (e) {
      throw Exception('Failed to save prescription file: $e');
    }
  }
  
  // Get readable file type from extension
  static String getFileType(String extension) {
    final ext = extension.toLowerCase();
    
    if (ext == '.pdf') {
      return 'PDF Document';
    } else if (ext == '.jpg' || ext == '.jpeg') {
      return 'JPEG Image';
    } else if (ext == '.png') {
      return 'PNG Image';
    } else if (ext == '.gif') {
      return 'GIF Image';
    } else if (ext == '.bmp') {
      return 'Bitmap Image';
    } else if (ext == '.webp') {
      return 'WebP Image';
    } else if (ext == '.doc' || ext == '.docx') {
      return 'Word Document';
    } else if (ext == '.txt') {
      return 'Text File';
    } else if (ext == '.rtf') {
      return 'Rich Text File';
    } else {
      return 'File';
    }
  }
  
  // Delete prescription file
  static Future<bool> deletePrescriptionFile(String filePath) async {
    return await deleteFile(filePath);
  }
  
  // Check if file is within allowed size (10MB)
  static bool isFileSizeValid(File file, {int maxSizeMB = 10}) {
    final sizeInBytes = file.lengthSync();
    final maxSizeBytes = maxSizeMB * 1024 * 1024;
    return sizeInBytes <= maxSizeBytes;
  }
  
  // Get file MIME type
  static String getMimeType(String filename) {
    final extension = getFileExtension(filename);
    
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.bmp':
        return 'image/bmp';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.txt':
        return 'text/plain';
      case '.rtf':
        return 'application/rtf';
      default:
        return 'application/octet-stream';
    }
  }
  
  // Get all files in directory
  static Future<List<File>> getFilesInDirectory(String dirPath) async {
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      return [];
    }
    
    final files = await directory.list().where((entity) => entity is File).toList();
    return files.cast<File>();
  }
  
  // Get directory size
  static Future<int> getDirectorySize(String dirPath) async {
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      return 0;
    }
    
    int totalSize = 0;
    final files = await getFilesInDirectory(dirPath);
    
    for (final file in files) {
      totalSize += await file.length();
    }
    
    // Check subdirectories recursively
    final subDirs = await directory.list().where((entity) => entity is Directory).toList();
    for (final subDir in subDirs.cast<Directory>()) {
      totalSize += await getDirectorySize(subDir.path);
    }
    
    return totalSize;
  }
  
  // Clear directory (delete all files)
  static Future<void> clearDirectory(String dirPath) async {
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      return;
    }
    
    final files = await getFilesInDirectory(dirPath);
    for (final file in files) {
      await file.delete();
    }
    
    // Clear subdirectories
    final subDirs = await directory.list().where((entity) => entity is Directory).toList();
    for (final subDir in subDirs.cast<Directory>()) {
      await clearDirectory(subDir.path);
    }
  }
}