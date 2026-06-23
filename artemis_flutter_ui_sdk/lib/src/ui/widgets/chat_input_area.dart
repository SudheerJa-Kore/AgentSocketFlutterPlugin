import 'package:flutter/material.dart';

class ChatInputArea extends StatefulWidget {
  static const defaultInputText =
      '';

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;
  final String? initialText;

  const ChatInputArea({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSend,
    this.initialText,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  @override
  void initState() {
    super.initState();
    if (widget.controller.text.isEmpty) {
      final text = widget.initialText ?? ChatInputArea.defaultInputText;
      if (text.isNotEmpty) {
        widget.controller.text = text;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SafeArea(
              top: false,
              right: false,
              minimum: const EdgeInsets.fromLTRB(16, 12, 0, 10),
              child: TextField(
                controller: widget.controller,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: widget.enabled ? (_) => widget.onSend() : null,
                enabled: widget.enabled,
              ),
            ),
          ),
          SafeArea(
            top: false,
            left: false,
            minimum: const EdgeInsets.fromLTRB(8, 12, 16, 10),
            child: SizedBox(
              width: 40,
              height: 40,
              child: FloatingActionButton.small(
                onPressed: widget.enabled ? widget.onSend : null,
                child: const Icon(Icons.send, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
