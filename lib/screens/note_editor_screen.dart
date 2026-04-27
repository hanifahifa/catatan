// lib/screens/note_editor_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/note.dart';
import '../helpers/file_helper.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final FileHelper _fileHelper = FileHelper();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isSaving = false;
  File? _imageFile;               // gambar baru yang dipilih (belum disimpan)
  bool _hasExistingImage = false; // gambar yang sudah tersimpan sebelumnya

  bool get _isEditMode => widget.note != null;
  String get _noteId => widget.note?.id ?? _fileHelper.generateNoteId();
  late final String _resolvedNoteId;

  @override
  void initState() {
    super.initState();
    _resolvedNoteId = _noteId;
    if (_isEditMode) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _hasExistingImage = widget.note!.hasImage;
      _loadExistingImage();
    }
  }

  // Memuat gambar yang sudah tersimpan untuk ditampilkan
  Future<void> _loadExistingImage() async {
    final imageFile = await _fileHelper.getNoteImageFile(_resolvedNoteId);
    if (mounted && imageFile != null) {
      setState(() => _imageFile = imageFile);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Memilih gambar baru dari galeri
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (xFile != null && mounted) {
      setState(() => _imageFile = File(xFile.path));
    }
  }

  // Menghapus gambar dari catatan
  Future<void> _removeImage() async {
    setState(() {
      _imageFile = null;
      _hasExistingImage = false;
    });
  }

  // Menyimpan catatan ke sistem file
  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul atau isi catatan tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Simpan teks catatan
      await _fileHelper.saveNote(
        _resolvedNoteId,
        _titleController.text.trim(),
        _contentController.text.trim(),
      );

      // Simpan gambar baru jika ada
      final isNewImage = _imageFile != null &&
          !_imageFile!.path.contains(_resolvedNoteId);
      if (isNewImage) {
        await _fileHelper.saveNoteImage(_resolvedNoteId, _imageFile!.path);
      }

      // Hapus gambar jika pengguna memilih untuk menghapusnya
      if (!_hasExistingImage && !isNewImage) {
        final existingImage =
            await _fileHelper.getNoteImageFile(_resolvedNoteId);
        if (existingImage != null) await existingImage.delete();
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan catatan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Catatan' : 'Catatan Baru'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Simpan',
                  onPressed: _saveNote,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Judul catatan',
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Tulis catatanmu di sini...',
                border: InputBorder.none,
              ),
              maxLines: null,
              minLines: 8,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (_imageFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _imageFile!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _removeImage,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Hapus Gambar',
                    style: TextStyle(color: Colors.red)),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Lampirkan Gambar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}