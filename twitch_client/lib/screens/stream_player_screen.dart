import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../models/twitch_models.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../widgets/glass_button.dart';

/// Stream player screen with video and chat
class StreamPlayerScreen extends StatefulWidget {
  final Stream stream;

  const StreamPlayerScreen({super.key, required this.stream});

  @override
  State<StreamPlayerScreen> createState() => _StreamPlayerScreenState();
}

class _StreamPlayerScreenState extends State<StreamPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  ChatService? _chatService;
  bool _isChatVisible = true;
  bool _isPiPSupported = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _checkPiPSupport();
  }

  Future<void> _initializePlayer() async {
    // Construct Twitch stream URL
    // Note: In production, you need to get the actual HLS URL from Twitch API
    final streamUrl = _getStreamUrl(widget.stream.userId);

    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(streamUrl),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: true,
      ),
    );

    await _videoController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      looping: false,
      showControlsOnInitialize: true,
      placeholder: Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFF9146FF),
          ),
        ),
      ),
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading stream',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
              ),
            ],
          ),
        );
      },
    );

    setState(() {});
  }

  String _getStreamUrl(String userId) {
    // This is a placeholder - in production you need to:
    // 1. Get the stream key from Twitch API
    // 2. Construct the HLS URL
    // For now, using a test stream URL
    return 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';
  }

  Future<void> _checkPiPSupport() async {
    // Check if Picture-in-Picture is supported
    // On iOS, this requires native implementation
    setState(() {
      _isPiPSupported = true; // Placeholder
    });
  }

  void _togglePiP() {
    if (_isPiPSupported && _chewieController != null) {
      // Enable PiP mode
      // This requires native iOS implementation
      // chewieController?.enterPictureInPictureMode();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Picture-in-Picture activated'),
          backgroundColor: Color(0xFF9146FF),
        ),
      );
    }
  }

  void _initializeChat() {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (authService.isAuthenticated && authService.currentUser != null) {
      _chatService = ChatService();
      _chatService!.connect(
        authService.currentUser!.login,
        authService.accessToken!,
      );
      _chatService!.joinChannel(widget.stream.userLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return _buildLandscapeLayout();
          } else {
            return _buildPortraitLayout();
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isChatVisible = !_isChatVisible;
          });
        },
        backgroundColor: const Color(0xFF9146FF),
        child: Icon(_isChatVisible ? Icons.chat_bubble_outline : Icons.chat_bubble),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        // Video Player
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.black,
            child: _chewieController != null &&
                    _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF9146FF),
                    ),
                  ),
          ),
        ),
        // Stream Info
        Expanded(
          flex: 2,
          child: _buildStreamInfo(),
        ),
        // Chat (if visible)
        if (_isChatVisible)
          Expanded(
            flex: 2,
            child: _buildChatPanel(),
          ),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Video Player
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.black,
            child: _chewieController != null &&
                    _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF9146FF),
                    ),
                  ),
          ),
        ),
        // Chat (if visible in landscape)
        if (_isChatVisible)
          Expanded(
            flex: 1,
            child: _buildChatPanel(),
          ),
      ],
    );
  }

  Widget _buildStreamInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF9146FF),
                child: Text(
                  widget.stream.userName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.stream.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.stream.gameName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // PiP Button
              if (_isPiPSupported)
                IconButton(
                  icon: const Icon(Icons.picture_in_picture_alt),
                  color: const Color(0xFF9146FF),
                  onPressed: _togglePiP,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.stream.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.visibility,
                size: 16,
                color: Colors.white54,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.stream.viewerCount}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatPanel() {
    if (_chatService == null) {
      return Container(
        color: const Color(0xFF18181B),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white24,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign in to chat',
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 16),
              GlassButton(
                onPressed: _initializeChat,
                icon: Icons.login,
                text: 'Connect Chat',
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF18181B),
      child: Column(
        children: [
          // Chat messages
          Expanded(
            child: Consumer<ChatService>(
              builder: (context, chatService, child) {
                final messages = chatService.messages;
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${message.displayName}: ',
                              style: TextStyle(
                                color: message.color != null
                                    ? Color(int.parse(message.color!.substring(1), radix: 16) + 0xFF000000)
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: message.message,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Chat input
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    final controller = TextEditingController();
    
    return Container(
      padding: const EdgeInsets.all(8),
      color: const Color(0xFF1F1F23),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Send a message',
                hintStyle: const TextStyle(color: Colors.white38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFF2D2D30),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted: (text) {
                if (text.isNotEmpty && _chatService != null) {
                  _chatService!.sendMessage(text);
                  controller.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF9146FF)),
            onPressed: () {
              if (controller.text.isNotEmpty && _chatService != null) {
                _chatService!.sendMessage(controller.text);
                controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _chatService?.disconnect();
    super.dispose();
  }
}
