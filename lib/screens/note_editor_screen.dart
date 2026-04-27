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

  // ✅ MULTI IMAGE
  List<File> _images = [];

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

      // 🔵 LOAD EXISTING IMAGES
      _loadExistingImages();
    }
  }

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
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // =============================
  // PICK MULTIPLE IMAGE
  // =============================
  Future<void> _pickImages() async {
    final picker = ImagePicker();

    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null && mounted) {
      setState(() {
        _images = pickedFiles.map((e) => File(e.path)).toList();
      });
    }
  }

  // =============================
  // REMOVE IMAGE (BY INDEX)
  // =============================
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  // =============================
  // SAVE
  // =============================
  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul atau isi tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // SAVE TEXT
      await _fileHelper.saveNote(
        _resolvedNoteId,
        _titleController.text.trim(),
        _contentController.text.trim(),
      );

      // SAVE IMAGES (MULTI)
      await _fileHelper.saveNoteImages(
        _resolvedNoteId,
        _images.map((e) => e.path).toList(),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // =============================
  // UI
  // =============================
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
                  onPressed: _saveNote,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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

            // =============================
            // IMAGE LIST
            // =============================
            if (_images.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
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
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),

            // =============================
            // ADD IMAGE BUTTON
            // =============================
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