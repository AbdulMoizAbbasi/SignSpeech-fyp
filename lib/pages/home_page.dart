// lib/pages/home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import '../routes.dart';

// NEW: Imports for API calls
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  bool _isProfileMenuOpen = false;
  DateTime? _lastBackPressTime;
  late VideoPlayerController _videoController;
  bool _isPlaying = true;
  double _videoPosition = 0.0;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  bool _isRecording = false;
  final TextEditingController _textController = TextEditingController();
  late AnimationController _micAnimationController;

  // NEW: State for API call
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize video controller with the asset
    _videoController = VideoPlayerController.asset('assets/sample_video.mp4')
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
        _videoController.setLooping(true);
      });

    // Add listener to track video position
    _videoController.addListener(_videoListener);

    // Initialize microphone animation
    _micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  // NEW: Extracted listener
  void _videoListener() {
    if (mounted) {
      setState(() {
        if (_videoController.value.isInitialized &&
            _videoController.value.duration.inMilliseconds > 0) {
          _videoPosition =
              _videoController.value.position.inMilliseconds /
              _videoController.value.duration.inMilliseconds;
        } else {
          _videoPosition = 0.0;
        }
      });
    }
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoListener); // NEW: Remove listener
    _videoController.dispose();
    _recordingTimer?.cancel();
    _micAnimationController.dispose();
    _textController.dispose(); // NEW: Dispose text controller
    super.dispose();
  }

  // NEW: Function to update the video player from a URL
  Future<void> _updateVideoPlayerFromUrl(String videoUrl) async {
    // Dispose the old controller
    await _videoController.pause();
    _videoController.removeListener(_videoListener);
    await _videoController.dispose();

    // Initialize the new controller from a NETWORK URL
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize()
          .then((_) {
            setState(() {
              _isLoading = false; // Video loaded
            });
            _videoController.play();
            _videoController.setLooping(true);
            _isPlaying = true;
          })
          .catchError((error) {
            setState(() {
              _isLoading = false;
            });
            _showErrorSnackBar("Failed to load video: $error");
            // Revert to sample video on error
            _updateVideoPlayerFromAsset('assets/sample_video.mp4');
          });
    _videoController.addListener(_videoListener);
  }

  // NEW: Helper to load asset video (for fallback)
  Future<void> _updateVideoPlayerFromAsset(String assetPath) async {
    await _videoController.pause();
    _videoController.removeListener(_videoListener);
    await _videoController.dispose();

    _videoController = VideoPlayerController.asset(assetPath)
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
        _videoController.setLooping(true);
        _isPlaying = true;
      });
    _videoController.addListener(_videoListener);
  }

  // NEW: Function to call the API
  Future<void> _sendTextToApi() async {
    final text = _textController.text;
    _showErrorSnackBar('Send button tapped');
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    // --- IMPORTANT: API URL ---
    // Use 'http://10.0.2.2:8000' for Android Emulator
    // Use 'http://127.0.0.1:8000' for Desktop app or Web
    // Use your server's LAN IP (e.g., 'http://192.168.1.5:8000') for a real device
    final url = Uri.parse('http://192.168.100.24:8000/predict/video');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'text': text, 'fps': 30}),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final videoUrl = responseBody['video_url'];

        if (videoUrl != null) {
          // We got the URL, now update the player
          await _updateVideoPlayerFromUrl(videoUrl);
          _textController.clear();
        } else {
          _showErrorSnackBar('API returned success but no video URL.');
          setState(() => _isLoading = false);
        }
      } else {
        // Handle HTTP error
        _showErrorSnackBar(
          'API Error: ${response.statusCode} - ${response.body}',
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // Handle network/other errors
      _showErrorSnackBar(
        'Failed to connect to API. Is the server running? \nError: $e',
      );
      setState(() => _isLoading = false);
    }
  }

  // NEW: Helper for showing errors
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // ... (your existing _onWillPop code is fine) ...
    if (_isProfileMenuOpen) {
      setState(() => _isProfileMenuOpen = false);
      return false;
    }

    final now = DateTime.now();
    final bool mustWait =
        _lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2);

    if (mustWait) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    return true;
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _videoController.play();
      } else {
        _videoController.pause();
      }
    });
  }

  void _startRecording() {
    // ... (your existing _startRecording code is fine) ...
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds = timer.tick;
        });
      });
    });
  }

  void _stopRecording() {
    // ... (your existing _stopRecording code is fine) ...
    setState(() {
      _isRecording = false;
      _recordingTimer?.cancel();
      _recordingTimer = null;
    });
  }

  Widget _buildRecordingUI() {
    // ... (your existing _buildRecordingUI code is fine) ...
    if (!_isRecording) return const SizedBox.shrink();

    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _micAnimationController,
                builder: (context, child) {
                  return Icon(
                    Icons.mic,
                    size: 40,
                    color: Colors.red,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.red.withOpacity(
                          _micAnimationController.value,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 15),
              Text(
                'Recording: $_recordingSeconds',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.stop, size: 30, color: Colors.red),
                onPressed: _stopRecording,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFE0F7FA),
        body: Stack(
          children: [
            // ... (your existing background gradient) ...
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE0F7FA), Color(0xFFB3E5FC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Floating video container
            Positioned(
              top: MediaQuery.of(context).padding.top + 95,
              left: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    children: [
                      // Video Player
                      Container(
                        color: Colors.black,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_videoController.value.isInitialized)
                              AspectRatio(
                                aspectRatio: _videoController.value.aspectRatio,
                                child: VideoPlayer(_videoController),
                              )
                            else
                              const Center(child: CircularProgressIndicator()),

                            // Play/Pause overlay
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: _togglePlayPause,
                                child: Container(
                                  color: Colors.transparent,
                                  child: Center(
                                    child: Icon(
                                      _isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      size: 50,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Video progress indicator
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: LinearProgressIndicator(
                                value: _videoPosition,
                                backgroundColor: Colors.grey[700],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF00BCD4),
                                ),
                                minHeight: 3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Video description
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          _isLoading
                              ? "Generating video..."
                              : "This is a demonstration of sign language translation", // You can update this text
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Text input at the bottom (WhatsApp style)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // ... (your existing mic button) ...
                    GestureDetector(
                      onTap: () {
                        if (_isRecording) {
                          _stopRecording();
                        } else {
                          _startRecording();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F7FA),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: _isRecording
                              ? Colors.red
                              : const Color(0xFF0288D1),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Text input field
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F7FA),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: "Enter text to generate video...",
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Send button
                    // NEW: Wrapped in GestureDetector and show loading
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : _sendTextToApi, // NEW: Call API on tap
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00BCD4),
                          shape: BoxShape.circle,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 28,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ... (your existing profile icon and profile menu code is fine) ...
            // Profile icon in top right corner
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isProfileMenuOpen = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 30,
                    color: Color(0xFF0288D1),
                  ),
                ),
              ),
            ),

            // Profile menu sliding from right
            // if (_isProfileMenuOpen)
            //   GestureDetector(
            //     onTap: () {
            //       setState(() {
            //         _isProfileMenuOpen = false;
            //       });
            //     },
            //     behavior: HitTestBehavior.opaque,
            //     child: Container(color: Colors.black.withOpacity(0.3)),
            //   ),

            // Profile menu content
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              top: 0,
              right: _isProfileMenuOpen ? 0 : -300,
              bottom: 0,
              width: 280,
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping inside menu
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(
                          top: 60,
                          left: 20,
                          right: 20,
                          bottom: 20,
                        ),
                        color: const Color(0xFF0288D1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 45,
                                color: Color(0xFF0288D1),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "User Profile",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            StreamBuilder<User?>(
                              stream: FirebaseAuth.instance.authStateChanges(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Text(
                                    snapshot.data!.email ?? "user@example.com",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.white70,
                                    ),
                                  );
                                }
                                return const Text(
                                  "user@example.com",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white70,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Menu options
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildMenuItem(
                              icon: Icons.edit,
                              title: "Edit Profile",
                              onTap: () {},
                            ),
                            const Divider(height: 20, thickness: 0.8),
                            _buildMenuItem(
                              icon: Icons.settings,
                              title: "Settings",
                              onTap: () {},
                            ),
                            const Divider(height: 20, thickness: 0.8),
                            _buildMenuItem(
                              icon: Icons.help_outline,
                              title: "Instructions",
                              onTap: () {},
                            ),
                            const Divider(height: 20, thickness: 0.8),
                            _buildMenuItem(
                              icon: Icons.logout,
                              title: "Log Out",
                              onTap: () async {
                                await FirebaseAuth.instance.signOut();
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                );
                              },
                              isLogout: true,
                            ),
                          ],
                        ),
                      ),

                      // Close button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 30),
                            color: const Color(0xFF0288D1),
                            onPressed: () {
                              setState(() {
                                _isProfileMenuOpen = false;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Recording UI
            _buildRecordingUI(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    // ... (your existing _buildMenuItem code is fine) ...
    return ListTile(
      leading: Icon(
        icon,
        size: 26,
        color: isLogout ? Colors.red : const Color(0xFF0288D1),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: isLogout ? Colors.red : Colors.black87,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      minLeadingWidth: 5,
    );
  }
}
