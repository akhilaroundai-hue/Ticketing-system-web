import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../productivity/presentation/widgets/canned_response_dialog.dart';
import '../../../productivity/presentation/widgets/article_search_dialog.dart';
import '../../domain/entities/comment.dart';
import '../providers/comments_provider.dart';

/// Comments Section Widget - Chat-like interface for ticket comments
class CommentsSection extends ConsumerStatefulWidget {
  final String ticketId;
  final String currentUserName;

  const CommentsSection({
    super.key,
    required this.ticketId,
    required this.currentUserName,
  });

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  final _commentController = TextEditingController();
  final bool _isInternal = true;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final success = await ref
        .read(commentSubmitterProvider.notifier)
        .submitComment(
          ticketId: widget.ticketId,
          author: widget.currentUserName,
          body: _commentController.text.trim(),
          isInternal: _isInternal,
        );

    if (success && mounted) {
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment added successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _wrapSelection(String prefix, String suffix) {
    final text = _commentController.text;
    final selection = _commentController.selection;
    final start = selection.start;
    final end = selection.end;

    if (start < 0 || end < 0 || start > end) {
      _commentController.text = '$prefix$text$suffix';
      _commentController.selection = TextSelection.collapsed(
        offset: _commentController.text.length,
      );
      return;
    }

    final selectedText = text.substring(start, end);
    final newText = text.replaceRange(
      start,
      end,
      '$prefix$selectedText$suffix',
    );
    _commentController.text = newText;
    _commentController.selection = TextSelection(
      baseOffset: start + prefix.length,
      extentOffset: start + prefix.length + selectedText.length,
    );
  }

  void _insertAtLineStart(String insert) {
    final text = _commentController.text;
    final selection = _commentController.selection;
    final cursor = selection.start;

    if (cursor < 0) {
      _commentController.text = '$insert$text';
      _commentController.selection = TextSelection.collapsed(
        offset: insert.length,
      );
      return;
    }

    final lineStart = text.lastIndexOf('\n', cursor - 1) + 1;
    final newText = text.replaceRange(lineStart, lineStart, insert);
    _commentController.text = newText;
    final newOffset = cursor + insert.length;
    _commentController.selection = TextSelection.collapsed(offset: newOffset);
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsStreamProvider(widget.ticketId));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Comments',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Comments List
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No comments yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to comment',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isCurrentUser =
                        comment.author == widget.currentUserName;

                    return _CommentBubble(
                      comment: comment,
                      isCurrentUser: isCurrentUser,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Error loading comments: $err'),
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.flash_on, color: Colors.amber),
                      tooltip: 'Quick Response',
                      onPressed: () async {
                        final text = await showDialog<String>(
                          context: context,
                          builder: (_) => const CannedResponseDialog(),
                        );
                        if (text != null && mounted) {
                          _commentController.text = text;
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.menu_book, color: Colors.blue),
                      tooltip: 'Insert KB Article',
                      onPressed: () async {
                        final link = await showDialog<String>(
                          context: context,
                          builder: (_) => const ArticleSearchDialog(),
                        );
                        if (link != null && mounted) {
                          final currentText = _commentController.text;
                          final newText = currentText.isEmpty
                              ? link
                              : '$currentText\n\n$link';
                          _commentController.text = newText;
                        }
                      },
                    ),
                    TextButton(
                      onPressed: () {
                        _wrapSelection('**', '**');
                      },
                      child: const Text(
                        'B',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _insertAtLineStart('- ');
                      },
                      child: const Text('• List'),
                    ),
                    TextButton(
                      onPressed: () {
                        _wrapSelection('`', '`');
                      },
                      child: const Text('Code'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Input Field
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: _isInternal
                              ? 'Add internal note...'
                              : 'Add a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitComment(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton(
                      onPressed: _submitComment,
                      mini: true,
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final TicketComment comment;
  final bool isCurrentUser;

  const _CommentBubble({required this.comment, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: comment.isInternal
              ? Colors.orange.shade50
              : (isCurrentUser
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: comment.isInternal
              ? Border.all(color: Colors.orange.shade300, width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (comment.isInternal) ...[
                  Icon(Icons.lock, size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 4),
                ],
                Text(
                  comment.author,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: comment.isInternal ? Colors.orange.shade900 : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  comment.createdAt != null
                      ? timeago.format(comment.createdAt!)
                      : 'Unknown',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Body (markdown-rendered)
            MarkdownBody(
              data: comment.body,
              styleSheet: MarkdownStyleSheet.fromTheme(
                Theme.of(context),
              ).copyWith(p: const TextStyle(fontSize: 14, height: 1.4)),
            ),
            if (comment.isInternal) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'INTERNAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
