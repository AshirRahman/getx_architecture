// path: tools/combine_project.dart

// ignore_for_file: avoid_print

import 'dart:io';

/// =============================================================
/// 🔧 Project Combiner Script
/// =============================================================
/// Run: dart run tools/combine_project.dart
///
/// This script scans the entire project and combines all
/// relevant source files into a single text file inside
/// the tools/ folder.
/// =============================================================

// ── Folders to skip ──────────────────────────────────────────
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
  'tools', // skip tools folder itself
  'public',
];

// ── File extensions to include ───────────────────────────────
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

// ── Files to always skip ─────────────────────────────────────
const List<String> _skipFiles = [
  'pubspec.lock',
  '.flutter-plugins',
  '.flutter-plugins-dependencies',
  '.metadata',
  '.packages',
];

void main() {
  final projectRoot = Directory.current.path;
  final projectName =
      projectRoot.split(Platform.pathSeparator).last;

  print('');
  print('╔══════════════════════════════════════════════════╗');
  print('║        🔧 Project Combiner Script               ║');
  print('╠══════════════════════════════════════════════════╣');
  print('║  Project : $projectName');
  print('║  Root    : $projectRoot');
  print('╚══════════════════════════════════════════════════╝');
  print('');

  final buffer = StringBuffer();
  var fileCount = 0;
  var totalLines = 0;

  // ── Header ─────────────────────────────────────────────────
  buffer.writeln('=' * 70);
  buffer.writeln('  PROJECT: $projectName');
  buffer.writeln('  Generated: ${DateTime.now()}');
  buffer.writeln('=' * 70);
  buffer.writeln('');

  // ── Collect files ──────────────────────────────────────────
  final files = _collectFiles(Directory(projectRoot));
  files.sort((a, b) => a.path.compareTo(b.path));

  // ── Table of Contents ──────────────────────────────────────
  buffer.writeln('─' * 70);
  buffer.writeln('  📋 TABLE OF CONTENTS (${files.length} files)');
  buffer.writeln('─' * 70);
  for (var i = 0; i < files.length; i++) {
    final relativePath = _relativePath(files[i].path, projectRoot);
    buffer.writeln('  ${(i + 1).toString().padLeft(3)}. $relativePath');
  }
  buffer.writeln('');
  buffer.writeln('=' * 70);
  buffer.writeln('');

  // ── File contents ──────────────────────────────────────────
  for (final file in files) {
    final relativePath = _relativePath(file.path, projectRoot);
    final content = file.readAsStringSync();
    final lines = content.split('\n').length;

    buffer.writeln('┌${"─" * 68}┐');
    buffer.writeln('│ 📄 FILE: $relativePath');
    buffer.writeln('│ Lines: $lines');
    buffer.writeln('└${"─" * 68}┘');
    buffer.writeln('');
    buffer.writeln('// path: $relativePath');
    buffer.writeln('');
    buffer.writeln(content);
    buffer.writeln('');
    buffer.writeln('');

    fileCount++;
    totalLines += lines;

    print('  ✅ $relativePath ($lines lines)');
  }

  // ── Footer ─────────────────────────────────────────────────
  buffer.writeln('=' * 70);
  buffer.writeln('  📊 SUMMARY');
  buffer.writeln('  Total Files : $fileCount');
  buffer.writeln('  Total Lines : $totalLines');
  buffer.writeln('=' * 70);

  // ── Write output ───────────────────────────────────────────
  final outputDir = Directory('$projectRoot${Platform.pathSeparator}tools');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final outputFile = File(
    '${outputDir.path}${Platform.pathSeparator}${projectName}_full_project.txt',
  );
  outputFile.writeAsStringSync(buffer.toString());

  print('');
  print('╔══════════════════════════════════════════════════╗');
  print('║  ✅ DONE!                                       ║');
  print('╠══════════════════════════════════════════════════╣');
  print('║  Files   : $fileCount');
  print('║  Lines   : $totalLines');
  print('║  Output  : tools/${projectName}_full_project.txt');
  print('╚══════════════════════════════════════════════════╝');
  print('');
}

/// Recursively collects all relevant files from [dir].
List<File> _collectFiles(Directory dir) {
  final result = <File>[];

  for (final entity in dir.listSync(followLinks: false)) {
    final name = entity.path.split(Platform.pathSeparator).last;

    if (entity is Directory) {
      // Skip excluded directories
      if (_skipDirs.contains(name)) continue;
      result.addAll(_collectFiles(entity));
    } else if (entity is File) {
      // Skip excluded files
      if (_skipFiles.contains(name)) continue;

      // Check extension
      final ext = _getExtension(name);
      if (_includeExtensions.contains(ext)) {
        // Skip binary / too large files (>500KB)
        if (entity.lengthSync() > 500 * 1024) {
          print('  ⚠️  Skipped (too large): $name');
          continue;
        }
        result.add(entity);
      }
    }
  }

  return result;
}

/// Returns the file extension including the dot, e.g. `.dart`.
String _getExtension(String filename) {
  // Handle dotfiles like .gitignore
  if (filename.startsWith('.') && !filename.contains('.', 1)) {
    return filename; // e.g. ".gitignore"
  }
  final dotIndex = filename.lastIndexOf('.');
  if (dotIndex == -1) return '';
  return filename.substring(dotIndex);
}

/// Returns a relative path from [root].
String _relativePath(String fullPath, String root) {
  var relative = fullPath.replaceFirst(root, '');
  if (relative.startsWith(Platform.pathSeparator)) {
    relative = relative.substring(1);
  }
  return relative;
}
