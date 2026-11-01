import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recording_item.dart';
import '../services/storage_service.dart';

class RecordingsLibrarySheet extends StatelessWidget {
  final List<RecordingItem> items;
  final VoidCallback onRefresh;

  const RecordingsLibrarySheet({
    super.key,
    required this.items,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1523),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.video_library_rounded,
                      color: Color(0xFFFF7A00),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recordings Library',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${items.length} ${items.length == 1 ? "video" : "videos"} saved',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Flexible(
            child: items.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildRecordingCard(context, item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.movie_creation_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 14),
          const Text(
            'No recordings yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your recorded videos will appear here with audio tracks info.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingCard(BuildContext context, RecordingItem item) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    final dateStr = dateFormat.format(item.createdAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161E2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A1B14), Color(0xFF1D263B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(
              Icons.play_circle_fill_rounded,
              color: Color(0xFFFF7A00),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateStr • ${item.formattedFileSize} • ${item.resolution}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    if (item.hasSystemAudio)
                      _badge(
                        '🎧 System Audio',
                        const Color(0xFFFF7A00),
                      ),
                    if (item.hasMicAudio)
                      _badge(
                        '🎙️ Mic',
                        const Color(0xFF00E5FF),
                      ),
                    if (!item.hasSystemAudio && !item.hasMicAudio)
                      _badge(
                        'No Audio',
                        Colors.grey,
                      ),
                  ],
                ),
              ],
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Play recording',
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  color: Color(0xFFFF7A00),
                  size: 26,
                ),
                onPressed: () {
                  StorageService().playRecording(item.filePath);
                },
              ),
              IconButton(
                tooltip: 'Show in folder',
                icon: const Icon(
                  Icons.folder_open_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () {
                  StorageService().showInFolder(item.filePath);
                },
              ),
              IconButton(
                tooltip: 'Delete recording',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF131A29),
                      title: const Text('Delete Recording?'),
                      content: Text('Delete "${item.title}" permanently?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await StorageService().deleteRecording(item);
                    onRefresh();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
