// Model Note digunakan untuk merepresentasikan data sebuah catatan.
class Note {

  // Menyimpan ID unik dari setiap catatan.
  final String id;

  // Menyimpan judul catatan.
  final String title;

  // Menyimpan isi atau konten catatan.
  final String content;

  // Menyimpan daftar path gambar yang terkait dengan catatan.
  final List<String> imagePaths;

  // Konstruktor Note untuk menginisialisasi objek catatan.
  const Note({

    // ID catatan wajib diisi.
    required this.id,

    // Judul catatan wajib diisi.
    required this.title,

    // Isi catatan wajib diisi.
    required this.content,

    // Daftar path gambar bersifat opsional.
    // Jika tidak diberikan, nilainya berupa list kosong.
    this.imagePaths = const [],
  });
}