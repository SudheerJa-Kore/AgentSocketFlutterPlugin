import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Renders assistant message content with markdown styling.
class MarkdownMessage extends StatelessWidget {
  final String content;
  final Color textColor;
  final Color linkColor;
  final Color codeBackgroundColor;

  const MarkdownMessage({
    super.key,
    required this.content,
    required this.textColor,
    required this.linkColor,
    required this.codeBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      color: textColor,
      fontSize: 16,
      height: 1.45,
    );

    return MarkdownBody(
      data: content,
      shrinkWrap: true,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: baseStyle,
        pPadding: EdgeInsets.zero,
        h1: baseStyle.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
        h2: baseStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
        h3: baseStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
        h4: baseStyle.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
        h5: baseStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        h6: baseStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        strong: baseStyle.copyWith(fontWeight: FontWeight.w700),
        em: baseStyle.copyWith(fontStyle: FontStyle.italic),
        a: baseStyle.copyWith(
          color: linkColor,
          decoration: TextDecoration.underline,
          decorationColor: linkColor,
        ),
        code: baseStyle.copyWith(
          fontFamily: 'monospace',
          fontSize: 14,
          backgroundColor: codeBackgroundColor,
        ),
        codeblockDecoration: BoxDecoration(
          color: codeBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        blockquote: baseStyle.copyWith(
          color: textColor.withValues(alpha: 0.85),
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: linkColor.withValues(alpha: 0.6),
              width: 3,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
        listBullet: baseStyle,
        listIndent: 24,
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: textColor.withValues(alpha: 0.2)),
          ),
        ),
        tableHead: baseStyle.copyWith(fontWeight: FontWeight.w700),
        tableBody: baseStyle,
        tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        tableBorder: TableBorder.all(
          color: textColor.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}
