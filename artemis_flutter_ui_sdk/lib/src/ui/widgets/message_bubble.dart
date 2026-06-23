import 'package:artemis_flutter_socket_sdk/artemis_flutter_socket_sdk.dart';
import 'package:flutter/material.dart';
import 'carousel_message.dart';
import 'markdown_message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final ThemeConfig theme;
  final bool enableMarkdown;
  final bool enableCarousel;

  const MessageBubble({
    super.key,
    required this.message,
    required this.theme,
    required this.enableMarkdown,
    this.enableCarousel = true,
  });

  bool get _hasCarousel =>
      enableCarousel &&
      message.richContent?.carousel != null &&
      message.richContent!.carousel!.cards.isNotEmpty;

  bool get _hasText => message.content.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final useMarkdown = !isUser && enableMarkdown && _hasText;
    final isRich = !isUser && _hasCarousel;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(
          horizontal: isRich ? 12 : 16,
          vertical: 12,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * (isRich ? 0.95 : 0.7),
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(theme.borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_hasText)
              if (useMarkdown)
                MarkdownMessage(
                  content: message.content,
                  textColor: Colors.black87,
                  linkColor: Theme.of(context).colorScheme.primary,
                  codeBackgroundColor: Colors.black.withValues(alpha: 0.06),
                )
              else
                Text(
                  message.content,
                  style: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
            if (_hasCarousel) ...[
              if (_hasText) const SizedBox(height: 12),
              CarouselMessage(
                carousel: message.richContent!.carousel!,
                borderRadius: theme.borderRadius,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: isUser ? Colors.white70 : Colors.black45,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
