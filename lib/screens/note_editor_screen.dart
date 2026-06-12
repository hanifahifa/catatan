// Mengimpor library dart:io untuk mengelola file gambar pada perangkat.
import 'dart:io';

// Mengimpor package Material Design Flutter.
import 'package:flutter/material.dart';

// Mengimpor package image_picker untuk memilih gambar dari galeri perangkat.
import 'package:image_picker/image_picker.dart';

// Mengimpor model Note sebagai representasi data catatan.
import '../models/note.dart';

// Mengimpor helper untuk operasi penyimpanan file catatan dan gambar.
import '../helpers/file_helper.dart';

// Widget halaman editor catatan.
class NoteEditorScreen extends StatefulWidget {

  // Data catatan yang akan diedit. Bernilai null jika membuat catatan baru.
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

// State yang mengatur logika dan tampilan halaman editor.
class _NoteEditorScreenState extends State<NoteEditorScreen> {

  // Objek helper untuk mengelola file.
  final FileHelper _fileHelper = FileHelper();

  // Controller untuk input judul catatan.
  final TextEditingController _titleController = TextEditingController();

  // Controller untuk input isi catatan.
  final TextEditingController _contentController = TextEditingController();

  // Menandai proses penyimpanan sedang berlangsung atau tidak.
  bool _isSaving = false;

  // Menyimpan daftar gambar yang dipilih pengguna.
  List<File> _images = [];

  // Menentukan apakah halaman berada pada mode edit.
  bool get _isEditMode => widget.note != null;

  // Mengambil ID catatan yang ada atau membuat ID baru.
  String get _noteId => widget.note?.id ?? _fileHelper.generateNoteId();

  // Menyimpan ID catatan yang telah ditentukan.
  late final String _resolvedNoteId;

  @override
  void initState() {
    super.initState();

    // Menetapkan ID catatan.
    _resolvedNoteId = _noteId;

    // Jika mode edit, tampilkan data catatan yang sudah ada.
    if (_isEditMode) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;

      // Memuat gambar yang sudah tersimpan sebelumnya.
      _loadExistingImages();
    }
  }

  // Mengambil gambar yang telah tersimpan pada catatan.
  Future<void> _loadExistingImages() async {
    final files = await _fileHelper.getNoteImages(_resolvedNoteId);

    if (mounted) {
      setState(() {
        _images = files;
      });
    }
  }

  @override
  void dispose() {

    // Membersihkan controller untuk menghindari memory leak.
    _titleController.dispose();
    _contentController.dispose();

    super.dispose();
  }

  // =====================================
  // MEMILIH BANYAK GAMBAR DARI GALERI
  // =====================================
  Future<void> _pickImages() async {

    // Membuat objek ImagePicker.
    final picker = ImagePicker();

    // Membuka galeri dan memungkinkan memilih banyak gambar.
    final pickedFiles = await picker.pickMultiImage();

    // Jika pengguna memilih gambar.
    if (pickedFiles != null && mounted) {
      setState(() {

        // Mengubah hasil pemilihan menjadi daftar File.
        _images = pickedFiles.map((e) => File(e.path)).toList();
      });
    }
  }

  // =====================================
  // MENGHAPUS GAMBAR BERDASARKAN INDEX
  // =====================================
  void _removeImage(int index) {
    setState(() {

      // Menghapus gambar dari daftar.
      _images.removeAt(index);
    });
  }

  // =====================================
  // MENYIMPAN CATATAN
  // =====================================
  Future<void> _saveNote() async {

    // Validasi agar judul dan isi tidak kosong bersamaan.
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul atau isi tidak boleh kosong'),
        ),
      );
      return;
    }

    // Mengaktifkan indikator penyimpanan.
    setState(() => _isSaving = true);

    try {

      // Menyimpan judul dan isi catatan.
      await _fileHelper.saveNote(
        _resolvedNoteId,
        _titleController.text.trim(),
        _contentController.text.trim(),
      );

      // Menyimpan seluruh gambar yang dipilih.
      await _fileHelper.saveNoteImages(
        _resolvedNoteId,
        _images.map((e) => e.path).toList(),
      );

      // Kembali ke halaman sebelumnya setelah berhasil disimpan.
      if (mounted) Navigator.pop(context);

    } catch (e) {

      // Menampilkan pesan error jika terjadi kegagalan.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }

    } finally {

      // Menonaktifkan indikator penyimpanan.
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // =====================================
  // MEMBANGUN TAMPILAN HALAMAN
  // =====================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // AppBar halaman editor catatan.
      appBar: AppBar(
        title: Text(
          _isEditMode
              ? 'Edit Catatan'
              : 'Catatan Baru',
        ),

        actions: [

          // Menampilkan loading saat proses simpan.
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                )

              // Tombol simpan catatan.
              : IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveNote,
                ),
        ],
      ),

      // Isi halaman dapat digulir secara vertikal.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            // Input judul catatan.
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Judul',
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Divider(),

            // Input isi catatan.
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Isi catatan...',
                border: InputBorder.none,
              ),
              maxLines: null,
              minLines: 8,
            ),

            const SizedBox(height: 16),

            // Menampilkan daftar gambar jika tersedia.
            if (_images.isNotEmpty)
              SizedBox(
                height: 200,

                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,

                  itemBuilder: (context, index) {
                    return Stack(
                      children: [

                        // Menampilkan gambar.
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _images[index],
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // Tombol hapus gambar.
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),

            // Tombol untuk menambahkan gambar dari galeri.
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.image),
              label: const Text('Tambah Gambar'),
            ),
          ],
        ),
      ),
    );
  }
}