// Mengimpor library dart:io untuk mengelola file dan direktori pada perangkat.
import 'dart:io';

// Mengimpor package path_provider untuk mendapatkan lokasi penyimpanan aplikasi.
import 'package:path_provider/path_provider.dart';

// Mengimpor package path untuk mempermudah manipulasi path file.
import 'package:path/path.dart';

// Mengimpor package flutter_image_compress untuk mengompresi gambar sebelum disimpan.
import 'package:flutter_image_compress/flutter_image_compress.dart';

// Mengimpor model Note.
import '../models/note.dart';

// Kelas FileHelper digunakan untuk mengelola penyimpanan catatan dan gambar.
class FileHelper {

  // Membuat instance tunggal (Singleton).
  static final FileHelper _instance = FileHelper._internal();

  // Constructor private.
  FileHelper._internal();

  // Factory constructor untuk mengembalikan instance yang sama.
  factory FileHelper() => _instance;

  // =====================================
  // MENDAPATKAN DIREKTORI PENYIMPANAN
  // =====================================
  Future<Directory> _getNotesDirectory() async {

    // Mengambil direktori dokumen aplikasi.
    final docsDir = await getApplicationDocumentsDirectory();

    // Membuat folder notes di dalam direktori aplikasi.
    final notesDir = Directory(join(docsDir.path, 'notes'));

    // Jika folder belum ada maka dibuat terlebih dahulu.
    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }

    // Mengembalikan direktori notes.
    return notesDir;
  }

  // =====================================
  // MEMBUAT ID CATATAN OTOMATIS
  // =====================================
  String generateNoteId() {

    // Membuat ID unik berdasarkan timestamp saat ini.
    return 'note_${DateTime.now().millisecondsSinceEpoch}';
  }

  // =====================================
  // MENYIMPAN JUDUL DAN ISI CATATAN
  // =====================================
  Future<void> saveNote(
    String noteId,
    String title,
    String content,
  ) async {

    // Mengambil direktori notes.
    final notesDir = await _getNotesDirectory();

    // Membuat folder khusus untuk satu catatan.
    final noteDir = Directory(join(notesDir.path, noteId));

    // Jika folder belum ada maka dibuat.
    if (!await noteDir.exists()) {
      await noteDir.create(recursive: true);
    }

    // Membuat file content.txt.
    final file = File(join(noteDir.path, 'content.txt'));

    // Menyimpan judul dan isi catatan.
    await file.writeAsString('$title\n$content');
  }

  // =====================================
  // MEMBACA SATU CATATAN
  // =====================================
  Future<Note?> readNote(String noteId) async {

    // Mengambil direktori notes.
    final notesDir = await _getNotesDirectory();

    // Mengakses folder catatan berdasarkan ID.
    final noteDir = Directory(join(notesDir.path, noteId));

    // Mengakses file content.txt.
    final file = File(join(noteDir.path, 'content.txt'));

    // Jika file tidak ada maka kembalikan null.
    if (!await file.exists()) return null;

    // Membaca seluruh isi file.
    final rawContent = await file.readAsString();

    // Memisahkan isi berdasarkan baris.
    final lines = rawContent.split('\n');

    // Baris pertama sebagai judul.
    final title = lines.first;

    // Baris berikutnya sebagai isi catatan.
    final content =
        lines.length > 1 ? lines.sublist(1).join('\n') : '';

    // Mengambil seluruh gambar yang terkait dengan catatan.
    final imageFiles = await getNoteImages(noteId);

    // Membuat objek Note.
    return Note(
      id: noteId,
      title: title,
      content: content,
      imagePaths: imageFiles.map((e) => e.path).toList(),
    );
  }

  // =====================================
  // MENGAMBIL SELURUH CATATAN
  // =====================================
  Future<List<Note>> getAllNotes() async {

    // Mengambil direktori notes.
    final notesDir = await _getNotesDirectory();

    // Menyimpan daftar ID catatan.
    final List<String> noteIds = [];

    // Membaca seluruh folder catatan.
    await for (final entity in notesDir.list()) {
      if (entity is Directory) {
        noteIds.add(basename(entity.path));
      }
    }

    // Mengurutkan catatan terbaru di bagian atas.
    noteIds.sort((a, b) => b.compareTo(a));

    // Menyimpan hasil seluruh catatan.
    final List<Note> notes = [];

    // Membaca setiap catatan berdasarkan ID.
    for (final id in noteIds) {
      final note = await readNote(id);

      if (note != null) {
        notes.add(note);
      }
    }

    return notes;
  }

  // =====================================
  // MENYIMPAN BANYAK GAMBAR
  // =====================================
  Future<void> saveNoteImages(
    String noteId,
    List<String> paths,
  ) async {

    // Mengambil direktori notes.
    final notesDir = await _getNotesDirectory();

    // Mengakses folder catatan.
    final noteDir = Directory(join(notesDir.path, noteId));

    // Membuat folder jika belum ada.
    if (!await noteDir.exists()) {
      await noteDir.create(recursive: true);
    }

    // Mengambil seluruh file dalam folder catatan.
    final existingFiles = noteDir.listSync();

    // Menghapus gambar lama agar tidak terjadi duplikasi.
    for (var file in existingFiles) {
      if (file is File &&
          basename(file.path).startsWith('image_')) {
        await file.delete();
      }
    }

    // Menyimpan gambar baru satu per satu.
    for (int i = 0; i < paths.length; i++) {

      // Membaca file gambar asli.
      final originalBytes =
          await File(paths[i]).readAsBytes();

      // Mengompresi gambar untuk mengurangi ukuran file.
      final compressedBytes =
          await FlutterImageCompress.compressWithList(
        originalBytes,
        quality: 70,
        minWidth: 1080,
        minHeight: 1080,
        format: CompressFormat.jpeg,
      );

      // Membuat file gambar baru.
      final imageFile =
          File(join(noteDir.path, 'image_$i.jpg'));

      // Menyimpan hasil kompresi ke penyimpanan.
      await imageFile.writeAsBytes(compressedBytes);
    }
  }

  // =====================================
  // MENGAMBIL SELURUH GAMBAR CATATAN
  // =====================================
  Future<List<File>> getNoteImages(String noteId) async {

    // Mengambil direktori notes.
    final notesDir = await _getNotesDirectory();

    // Mengakses folder catatan.
    final noteDir = Directory(join(notesDir.path, noteId));

    // Jika folder tidak ada maka kembalikan list kosong.
    if (!await noteDir.exists()) return [];

    // Mengambil seluruh file dalam folder.
    final files = noteDir.listSync();

    // Memfilter hanya file gambar.
    final imageFiles = files
        .where(
          (f) =>
              f is File &&
              basename(f.path).startsWith('image_'),
        )
        .map((f) => File(f.path))
        .toList();

    // Mengurutkan gambar berdasarkan nama file.
    imageFiles.sort(
      (a, b) => a.path.compareTo(b.path),
    );

    return imageFiles;
  }

  // =====================================
  // MENGHAPUS CATATAN
  // =====================================
  Future<void> deleteNote(String noteId) async {

    // Mengambil direktori notes.
    final notesDir = await _getNotesDirectory();

    // Mengakses folder catatan berdasarkan ID.
    final noteDir = Directory(join(notesDir.path, noteId));

    // Jika folder ada maka hapus seluruh isi dan foldernya.
    if (await noteDir.exists()) {
      await noteDir.delete(recursive: true);
    }
  }
}