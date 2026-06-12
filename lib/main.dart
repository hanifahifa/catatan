// lib/main.dart

// Mengimpor package Material Design Flutter yang menyediakan berbagai widget UI.
import 'package:flutter/material.dart';

// Mengimpor halaman daftar catatan yang akan dijadikan halaman utama aplikasi.
import 'screens/note_list_screen.dart';

// Fungsi utama yang pertama kali dijalankan saat aplikasi dibuka.
void main() {
  // Menjalankan widget utama aplikasi yaitu MyApp.
  runApp(const MyApp());
}

// Widget utama aplikasi yang bersifat statis (tidak memiliki state).
class MyApp extends StatelessWidget {
  // Konstruktor MyApp.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Mengembalikan widget MaterialApp sebagai root aplikasi.
    return MaterialApp(
      // Judul aplikasi.
      title: 'Note-Taking App',

      // Menyembunyikan banner DEBUG di pojok kanan atas.
      debugShowCheckedModeBanner: false,

      // Konfigurasi tema aplikasi.
      theme: ThemeData(
        // Membuat skema warna berdasarkan warna utama (amber).
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
        ),

        // Mengaktifkan Material Design 3.
        useMaterial3: true,
      ),

      // Menentukan halaman pertama yang ditampilkan saat aplikasi dijalankan.
      home: const NoteListScreen(),
    );
  }
}