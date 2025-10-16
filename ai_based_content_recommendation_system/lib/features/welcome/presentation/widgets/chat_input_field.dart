import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onSubmitted;
  final bool enabled;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    this.enabled = true,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      // Rebuild when text changes to update send button appearance
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              enabled: widget.enabled,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onSubmitted: widget.enabled ? (text) {
                if (text.trim().isNotEmpty) {
                  widget.controller.clear();
                  widget.onSubmitted(text.trim());
                }
              } : null,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          
          
          // Send button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  if (widget.enabled && widget.controller.text.trim().isNotEmpty) {
                    final message = widget.controller.text.trim();
                    widget.controller.clear();
                    widget.onSubmitted(message);
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: widget.enabled && widget.controller.text.trim().isNotEmpty
                        ? LinearGradient(colors: AppTheme.primaryGradient)
                        : null,
                    color: widget.enabled && widget.controller.text.trim().isNotEmpty
                        ? null
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: widget.enabled && widget.controller.text.trim().isNotEmpty
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

