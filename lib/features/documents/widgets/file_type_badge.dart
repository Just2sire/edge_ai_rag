import 'package:flutter/material.dart';

/// Rounded icon that identifies a document format.
class FileTypeBadge extends StatelessWidget {
  const FileTypeBadge({
    super.key,
    required this.extension,
    this.size = 44,
  });

  /// File extension, with or without its leading dot.
  final String extension;

  /// Width and height of the badge.
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = _FileTypeStyle.fromExtension(extension);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: style.color.withValues(alpha: 0.24)),
      ),
      child: Icon(style.icon, size: size * 0.46, color: style.color),
    );
  }
}

/// Visual identity associated with a document format.
class _FileTypeStyle {
  const _FileTypeStyle({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  factory _FileTypeStyle.fromExtension(String extension) {
    switch (extension.replaceAll('.', '').toLowerCase()) {
      case 'pdf':
        return const _FileTypeStyle(
          icon: Icons.picture_as_pdf_rounded,
          color: Color(0xFFD64545),
        );
      case 'doc':
      case 'docx':
        return const _FileTypeStyle(
          icon: Icons.description_rounded,
          color: Color(0xFF3B6FD4),
        );
      case 'txt':
      case 'text':
        return const _FileTypeStyle(
          icon: Icons.text_snippet_rounded,
          color: Color(0xFFB08300),
        );
      case 'md':
        return const _FileTypeStyle(
          icon: Icons.code_rounded,
          color: Color(0xFF8A5CC7),
        );
      case 'json':
      case 'csv':
        return const _FileTypeStyle(
          icon: Icons.data_object_rounded,
          color: Color(0xFF2E8B80),
        );
      default:
        return const _FileTypeStyle(
          icon: Icons.insert_drive_file_rounded,
          color: Color(0xFF6B7280),
        );
    }
  }
}
