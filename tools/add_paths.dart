// path: tools/add_paths.dart

import 'dart:io';

const List<String> _skipDirs = [
  '.git',
  '.github',
  '.dart_tool',
  '.vscode',
  'build',
  'android',
  'ios',
  'web',
  'windows',
  'linux',
  'macos',
  '.gradle',
  '.idea',
  'tools', // we can skip tools or not. Let's not skip tools so we add it there too, wait, they want full project. Let's include tools.
  'public',
];

// Folders to explicitly skip for this script
final skipDirsFinal = _skipDirs.where((d) => d != 'tools').toList();

const List<String> _includeExtensions = [
  '.dart',
  '.yaml',
  '.yml',
  '.json',
  '.md',
  '.xml',
  '.properties',
  '.gradle',
  '.txt',
  '.env',
  '.gitignore',
  '.arb',
];

const List<String> _skipFiles = [
  'pubspec.lock',
  '.flutter-plugins',
  '.flutter-plugins-dependencies',
  '.metadata',
  '.packages',
];

void main() {
  final projectRoot = Directory.current.path;
  final rootDir = Directory(projectRoot);
  
  if (!rootDir.existsSync()) {
    print('Project root not found.');
    return;
  }

  final files = _collectFiles(rootDir);
  var modifiedCount = 0;

  for (final file in files) {
    var content = file.readAsStringSync();
    if (content.trim().isEmpty) continue; // Skip empty files

    final relativePath = _relativePath(file.path, projectRoot).replaceAll(r'\', '/');
    
    // Determine the comment syntax based on file extension
    String pathHeader = '';
    final ext = _getExtension(file.path).toLowerCase();
    
    if (ext == '.dart' || ext == '.gradle') {
      pathHeader = '// path: $relativePath';
    } else if (ext == '.yaml' || ext == '.yml' || ext == '.properties' || ext == '.env' || ext == '.gitignore') {
      pathHeader = '# path: $relativePath';
    } else if (ext == '.xml') {
      pathHeader = '<!-- path: $relativePath -->';
    } else if (ext == '.md') {
      pathHeader = '<!-- path: $relativePath -->';
    } else if (ext == '.json' || ext == '.arb') {
      // JSON doesn't support comments natively, so we might skip JSON or add it and break it?
      // Let's skip JSON/ARB for prepending paths, to prevent breaking parsing.
      continue;
    } else {
      pathHeader = '// path: $relativePath'; // default fallback
    }

    // Check if the file already has a path header
    if (!content.startsWith(pathHeader) && !content.startsWith('// path:') && !content.startsWith('# path:') && !content.startsWith('<!-- path:')) {
      content = '$pathHeader\n\n$content';
      file.writeAsStringSync(content);
      modifiedCount++;
      print('Added path to: $relativePath');
    }
  }

  print('Done! Modified $modifiedCount files.');
}

List<File> _collectFiles(Directory dir) {
  final result = <File>[];
  for (final entity in dir.listSync(followLinks: false)) {
    final name = entity.path.split(Platform.pathSeparator).last;
    
    if (entity is Directory) {
      if (skipDirsFinal.contains(name)) continue;
      result.addAll(_collectFiles(entity));
    } else if (entity is File) {
      if (_skipFiles.contains(name)) continue;
      
      final ext = _getExtension(name);
      if (_includeExtensions.contains(ext)) {
         result.add(entity);
      }
    }
  }
  return result;
}

String _getExtension(String filename) {
  if (filename.startsWith('.') && !filename.contains('.', 1)) {
    return filename; // e.g. ".gitignore"
  }
  final dotIndex = filename.lastIndexOf('.');
  if (dotIndex == -1) return '';
  return filename.substring(dotIndex);
}

String _relativePath(String fullPath, String root) {
  var relative = fullPath.replaceFirst(root, '');
  if (relative.startsWith(Platform.pathSeparator)) {
    relative = relative.substring(1);
  }
  return relative;
}
