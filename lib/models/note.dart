class Note {
  final String id;
  final String title;
  final String content;
  final List<String> imagePaths;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.imagePaths = const [],
  });
}