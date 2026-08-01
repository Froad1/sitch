import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/twitch_api_service.dart';
import '../models/twitch_models.dart';

/// Videos screen showing VODs (Video On Demand)
class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  String _selectedType = 'all'; // 'all', 'upload', 'archive', 'highlight'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVideos();
    });
  }

  Future<void> _loadVideos() async {
    final apiService = Provider.of<TwitchApiService>(context, listen: false);
    // Load videos from followed channels or featured creators
    // For now, we'll just show a placeholder
    await apiService.getFeaturedStreams(first: 10);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: const Color(0xFF18181B).withOpacity(0.9),
            title: const Text(
              'Videos',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onSelected: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                  _loadVideos();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'all',
                    child: Text('All Videos'),
                  ),
                  const PopupMenuItem(
                    value: 'upload',
                    child: Text('Uploads'),
                  ),
                  const PopupMenuItem(
                    value: 'archive',
                    child: Text('Past Broadcasts'),
                  ),
                  const PopupMenuItem(
                    value: 'highlight',
                    child: Text('Highlights'),
                  ),
                ],
              ),
            ],
          ),
          // Filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _selectedType == 'all',
                    onTap: () {
                      setState(() {
                        _selectedType = 'all';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Uploads',
                    selected: _selectedType == 'upload',
                    onTap: () {
                      setState(() {
                        _selectedType = 'upload';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Archives',
                    selected: _selectedType == 'archive',
                    onTap: () {
                      setState(() {
                        _selectedType = 'archive';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Highlights',
                    selected: _selectedType == 'highlight',
                    onTap: () {
                      setState(() {
                        _selectedType = 'highlight';
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Consumer<TwitchApiService>(
            builder: (context, apiService, child) {
              if (apiService.isLoading && apiService.recentVideos.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF9146FF),
                    ),
                  ),
                );
              }

              final videos = apiService.recentVideos;

              if (videos.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 64,
                          color: Colors.white24,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No videos found',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final video = videos[index];
                      return _VideoCard(video: video);
                    },
                    childCount: videos.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF9146FF)
              : const Color(0xFF2D2D30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF9146FF)
                : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Video card widget
class _VideoCard extends StatelessWidget {
  final Video video;

  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F23),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to video player
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      video.thumbnailUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: const Color(0xFF1F1F23),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: const Color(0xFF9146FF),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF1F1F23),
                          child: const Icon(
                            Icons.video_library,
                            color: Colors.white24,
                            size: 48,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Duration badge
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(video.duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Type badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getVideoTypeColor(video.type),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getVideoTypeLabel(video.type),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.userName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 14,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatViewCount(video.viewCount),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(video.createdAt),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(String duration) {
    // Parse ISO 8601 duration format (e.g., "1h30m15s")
    // Simplified implementation
    return duration;
  }

  String _formatViewCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M views';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K views';
    }
    return '$count views';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getVideoTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'upload':
        return Colors.blue;
      case 'archive':
        return Colors.purple;
      case 'highlight':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getVideoTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'upload':
        return 'UPLOAD';
      case 'archive':
        return 'ARCHIVE';
      case 'highlight':
        return 'HIGHLIGHT';
      default:
        return type.toUpperCase();
    }
  }
}
