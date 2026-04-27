import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/note.dart';

class FileHelper {
  static final FileHelper _instance = FileHelper._internal();
  FileHelper._internal();
  factory FileHelper() => _instance;

  // =============================
  // DIRECTORY
  // =============================
  Future<Directory> _getNotesDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final notesDir = Directory(join(docsDir.path, 'notes'));

    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }

    return notesDir;
  }

  // =============================
  // GENERATE ID
  // =============================
  String generateNoteId() {
    return 'note_${DateTime.now().millisecondsSinceEpoch}';
  }

  // =============================
  // SAVE TEXT
  // =============================
  Future<void> saveNote(String noteId, String title, String content) async {
    final notesDir = await _getNotesDirectory();
    final noteDir = Directory(join(notesDir.path, noteId));

    if (!await noteDir.exists()) {
      await noteDir.create(recursive: true);
    }

    final file = File(join(noteDir.path, 'content.txt'));
    await file.writeAsString('$title\n$content');
  }

  // =============================
  // READ NOTE
  // =============================
  Future<Note?> readNote(String noteId) async {
    final notesDir = await _getNotesDirectory();
    final noteDir = Directory(join(notesDir.path, noteId));

    final file = File(join(noteDir.path, 'content.txt'));
    if (!await file.exists()) return null;

    final rawContent = await file.readAsString();
    final lines = rawContent.split('\n');

    final title = lines.first;
    final content =
        lines.length > 1 ? lines.sublist(1).join('\n') : '';

    final imageFiles = await getNoteImages(noteId);

    return Note(
      id: noteId,
      title: title,
      content: content,
      imagePaths: imageFiles.map((e) => e.path).toList(),
    );
  }

  // =============================
  // GET ALL NOTES
  // =============================
  Future<List<Note>> getAllNotes() async {
    final notesDir = await _getNotesDirectory();
    final List<String> noteIds = [];

    await for (final entity in notesDir.list()) {
      if (entity is Directory) {
        noteIds.add(basename(entity.path));
      }
    }

    // terbaru di atas
    noteIds.sort((a, b) => b.compareTo(a));

    final List<Note> notes = [];
    for (final id in noteIds) {
      final note = await readNote(id);
      if (note != null) notes.add(note);
    }

    return notes;
  }

  // =============================
  // SAVE MULTIPLE IMAGES
  // =============================
  Future<void> saveNoteImages(String noteId, List<String> paths) async {
    final notesDir = await _getNotesDirectory();
    final noteDir = Directory(join(notesDir.path, noteId));

    if (!await noteDir.exists()) {
      await noteDir.create(recursive: true);
    }

    // 🔴 HAPUS GAMBAR LAMA (PENTING)
    final existingFiles = noteDir.listSync();
    for (var file in existingFiles) {
      if (file is File && basename(file.path).startsWith('image_')) {
        await file.delete();
      }
    }

    // 🔵 SIMPAN GAMBAR BARU
    for (int i = 0; i < paths.length; i++) {
      final originalBytes = await File(paths[i]).readAsBytes();

      final compressedBytes =
          await FlutterImageCompress.compressWithList(
        originalBytes,
        quality: 70,
        minWidth: 1080,
        minHeight: 1080,
        format: CompressFormat.jpeg,
      );

      final imageFile = File(join(noteDir.path, 'image_$i.jpg'));
      await imageFile.writeAsBytes(compressedBytes);
    }
  }

  // =============================
  // LOAD IMAGES
  // =============================
  Future<List<File>> getNoteImages(String noteId) async {
    final notesDir = await _getNotesDirectory();
    final noteDir = Directory(join(notesDir.path, noteId));

    if (!await noteDir.exists()) return [];

    final files = noteDir.listSync();

    final imageFiles = files
        .where((f) =>
            f is File &&
            basename(f.path).startsWith('image_'))
        .map((f) => File(f.path))
        .toList();

    // 🔴 WAJIB: biar urutan benar
    imageFiles.sort((a, b) => a.path.compareTo(b.path));

    return imageFiles;
  }

  // =============================
  // DELETE NOTE
  // =============================
  Future<void> deleteNote(String noteId) async {
    final notesDir = await _getNotesDirectory();
    final noteDir = Directory(join(notesDir.path, noteId));

    if (await noteDir.exists()) {
      await noteDir.delete(recursive: true);
    }
  }
}