// Mengimpor library dart:io untuk mengakses file pada penyimpanan perangkat.
import 'dart:io';

// Mengimpor package Material Design Flutter.
import 'package:flutter/material.dart';

// Mengimpor model Note yang digunakan sebagai struktur data catatan.
import '../models/note.dart';

// Mengimpor helper untuk operasi file seperti membaca, menyimpan, dan menghapus catatan.
import '../helpers/file_helper.dart';

// Mengimpor halaman editor catatan.
import 'note_editor_screen.dart';

// Widget halaman daftar catatan yang bersifat dinamis.
class NoteListScreen extends StatefulWidget {
  const NoteListScreen({super.key});

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

// State yang mengatur logika dan tampilan NoteListScreen.
class _NoteListScreenState extends State<NoteListScreen> {

  // Membuat objek FileHelper untuk mengelola penyimpanan file catatan.
  final FileHelper _fileHelper = FileHelper();

  // Menyimpan daftar catatan yang akan ditampilkan.
  List<Note> _notes = [];

  // Menandai apakah data masih dalam proses pemuatan.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Memuat seluruh catatan saat halaman pertama kali dibuka.
    _loadNotes();
  }

  // Fungsi untuk mengambil semua catatan dari penyimpanan.
  Future<void> _loadNotes() async {

    // Memastikan widget masih aktif sebelum mengubah state.
    if (!mounted) return;

    // Menampilkan indikator loading.
    setState(() => _isLoading = true);

    // Mengambil seluruh data catatan.
    final notes = await _fileHelper.getAllNotes();

    // Memastikan widget masih aktif.
    if (!mounted) return;

    // Memperbarui daftar catatan dan menghentikan loading.
    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  // Fungsi untuk menghapus catatan.
  Future<void> _deleteNote(String noteId) async {

    // Menampilkan dialog konfirmasi sebelum menghapus.
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: const Text(
          'Catatan beserta gambar akan dihapus permanen.',
        ),
        actions: [

          // Tombol batal.
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),

          // Tombol hapus.
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    // Jika pengguna menyetujui penghapusan.
    if (confirm == true) {

      // Menghapus catatan berdasarkan ID.
      await _fileHelper.deleteNote(noteId);

      // Memuat ulang daftar catatan.
      _loadNotes();
    }
  }

  // Fungsi untuk berpindah ke halaman editor catatan.
  Future<void> _navigateToEditor({Note? note}) async {

    // Membuka halaman editor dan mengirim data catatan jika mode edit.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(note: note),
      ),
    );

    // Memuat ulang daftar catatan setelah kembali dari editor.
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {

    // Membangun tampilan halaman.
    return Scaffold(

      // AppBar dengan judul halaman.
      appBar: AppBar(
        title: const Text('Catatan'),
      ),

      // Isi utama halaman.
      body: _isLoading

          // Menampilkan loading saat data sedang dimuat.
          ? const Center(
              child: CircularProgressIndicator(),
            )

          // Menampilkan pesan jika belum ada catatan.
          : _notes.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada catatan.\nTekan + untuk membuat catatan baru.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )

              // Menampilkan daftar catatan.
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {

                    // Mengambil data catatan berdasarkan indeks.
                    final note = _notes[index];

                    return Card(

                      // Memberikan jarak antar kartu catatan.
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),

                      child: ListTile(

                        // Menampilkan gambar pertama jika tersedia.
                        leading: note.imagePaths.isNotEmpty &&
                                File(note.imagePaths.first).existsSync()
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                  File(note.imagePaths.first),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )

                            // Menampilkan ikon jika tidak ada gambar.
                            : const Icon(
                                Icons.article_outlined,
                                color: Colors.grey,
                              ),

                        // Menampilkan judul catatan.
                        title: Text(
                          note.title.isEmpty
                              ? '(Tanpa judul)'
                              : note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Menampilkan isi singkat catatan.
                        subtitle: Text(
                          note.content.isEmpty
                              ? '(Tidak ada isi)'
                              : note.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Tombol hapus catatan.
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteNote(note.id),
                        ),

                        // Membuka editor saat catatan dipilih.
                        onTap: () => _navigateToEditor(note: note),
                      ),
                    );
                  },
                ),

      // Tombol tambah catatan baru.
      floatingActionButton: FloatingActionButton(

        // Membuka halaman editor dalam mode tambah catatan.
        onPressed: () => _navigateToEditor(),

        // Ikon tambah.
        child: const Icon(Icons.add),
      ),
    );
  }
}