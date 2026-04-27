class Note {
  final String id;
  final String title;
  final String content;
  final bool hasImage;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.hasImage = false,
  });
}