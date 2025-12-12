// lib/pages/home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import '../routes.dart';

// Imports for API calls
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

  // State for API call
  bool _isLoading = false;

  // State for Language Mode
  String _selectedMode = 'PSL'; // Options: 'PSL', 'ASL'

  // State to store the text displayed below the video
  String _lastGeneratedText = "";

  @override
  void initState() {
    super.initState();
    // Initialize video controller with the asset
    _videoController = VideoPlayerController.asset('assets/sample_video.mp4')
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
        _videoController.setLooping(false);
      });

    _videoController.addListener(_videoListener);

    _micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

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

        if (_videoController.value.isInitialized &&
            !_videoController.value.isPlaying &&
            _videoController.value.position >=
                _videoController.value.duration &&
            _videoController.value.duration.inMilliseconds > 0) {
          if (_isPlaying) {
            _isPlaying = false;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    _recordingTimer?.cancel();
    _micAnimationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _updateVideoPlayerFromUrl(String videoUrl) async {
    await _videoController.pause();
    _videoController.removeListener(_videoListener);
    await _videoController.dispose();

    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize()
          .then((_) {
            setState(() {
              _isLoading = false;
            });
            _videoController.play();
            _videoController.setLooping(false);
            _isPlaying = true;
          })
          .catchError((error) {
            setState(() {
              _isLoading = false;
            });
            _showErrorSnackBar("Failed to load video: $error");
            _updateVideoPlayerFromAsset('assets/sample_video.mp4');
          });
    _videoController.addListener(_videoListener);
  }

  Future<void> _updateVideoPlayerFromAsset(String assetPath) async {
    await _videoController.pause();
    _videoController.removeListener(_videoListener);
    await _videoController.dispose();

    _videoController = VideoPlayerController.asset(assetPath)
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
        _videoController.setLooping(false);
        _isPlaying = true;
      });
    _videoController.addListener(_videoListener);
  }

  bool _validateInput(String text) {
    if (_selectedMode == 'PSL') {
      if (RegExp(r'[a-zA-Z]').hasMatch(text)) {
        _showErrorSnackBar(
          'Input Error: For PSL, please use Urdu keyboard only.',
        );
        return false;
      }
    } else {
      if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) {
        _showErrorSnackBar(
          'Input Error: For ASL, please use English text only.',
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _sendTextToApi() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (!_validateInput(text)) return;

    setState(() {
      _isLoading = true;
    });

    final String endpoint = _selectedMode == 'PSL'
        ? '/predict/video'
        : '/predict/asl';

    final url = Uri.parse('http://192.168.76.8:8000$endpoint');

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
          await _updateVideoPlayerFromUrl(videoUrl);
          setState(() {
            _lastGeneratedText = text;
            _textController.clear();
          });
        } else {
          _showErrorSnackBar('API returned success but no video URL.');
          setState(() => _isLoading = false);
        }
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? response.body;
        _showErrorSnackBar('Server Error: $errorMsg');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to connect. Check IP/Internet.\nError: $e');
      setState(() => _isLoading = false);
    }
  }

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
      final bool isEnded =
          _videoController.value.isInitialized &&
          _videoController.value.position >= _videoController.value.duration &&
          _videoController.value.duration.inMilliseconds > 0;

      if (isEnded) {
        _videoController.seekTo(Duration.zero);
        _videoController.play();
        _isPlaying = true;
      } else {
        _isPlaying = !_isPlaying;
        if (_isPlaying) {
          _videoController.play();
        } else {
          _videoController.pause();
        }
      }
    });
  }

  void _startRecording() {
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
    setState(() {
      _isRecording = false;
      _recordingTimer?.cancel();
      _recordingTimer = null;
    });
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isEnded =
        _videoController.value.isInitialized &&
        _videoController.value.position >= _videoController.value.duration &&
        _videoController.value.duration.inMilliseconds > 0;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFF0288D1),
        body: Stack(
          children: [
            // 1. BACKGROUND (Full Screen Gradient)
            Container(
              height: size.height,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF01579B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -50,
                    left: -50,
                    child: CircleAvatar(
                      radius: 100,
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    right: -30,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),

            // 2. MAIN LAYOUT
            Column(
              children: [
                // Spacer for Header
                SizedBox(height: MediaQuery.of(context).padding.top + 70),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        // VIDEO PLAYER CARD
                        Container(
                          height: 300,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_videoController.value.isInitialized)
                                  AspectRatio(
                                    aspectRatio:
                                        _videoController.value.aspectRatio,
                                    child: VideoPlayer(_videoController),
                                  )
                                else
                                  const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),

                                Positioned.fill(
                                  child: GestureDetector(
                                    onTap: _togglePlayPause,
                                    child: Container(
                                      color: Colors.transparent,
                                      child: Center(
                                        child: Icon(
                                          isEnded
                                              ? Icons.replay
                                              : (_isPlaying
                                                    ? Icons.pause
                                                    : Icons.play_arrow),
                                          size: 60,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: LinearProgressIndicator(
                                    value: _videoPosition,
                                    backgroundColor: Colors.grey[800],
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF00BCD4),
                                        ),
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // TEXT INFO SECTION (Only if text generated)
                        if (_lastGeneratedText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30.0,
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 10),
                                Text(
                                  _lastGeneratedText,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // BOTTOM INPUT AREA
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: _buildModeSelector(),
                      ),
                      Row(
                        children: [
                          // Mic Button
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
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Icon(
                                _isRecording ? Icons.stop : Icons.mic,
                                color: _isRecording
                                    ? Colors.redAccent
                                    : Colors.white,
                                size: 26,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Text Input
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: TextField(
                                controller: _textController,
                                textDirection: _selectedMode == 'PSL'
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                decoration: InputDecoration(
                                  hintText: _selectedMode == 'PSL'
                                      ? "Enter Urdu text..."
                                      : "Enter English text...",
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Send Button (Loading State)
                          GestureDetector(
                            onTap: _isLoading ? null : _sendTextToApi,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _selectedMode == 'PSL'
                                    ? Colors.green
                                    : Colors.blue,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 4. BRANDING HEADER
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo.png',
                            width: 35,
                            height: 35,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "SignSpeech",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  GestureDetector(
                    onTap: () => setState(() => _isProfileMenuOpen = true),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 5. RECORDING OVERLAY
            _buildRecordingUI(),

            // 6. PROFILE MENU
            _buildProfileMenuOverlay(size),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildProfileMenuOverlay(Size size) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      top: 0,
      right: _isProfileMenuOpen ? 0 : -300,
      bottom: 0,
      width: 280,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            bottomLeft: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 50,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with Name Fetching
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 60,
                left: 20,
                right: 20,
                bottom: 30,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF0288D1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.4),
                        ),
                        child: const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF0288D1),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () =>
                            setState(() => _isProfileMenuOpen = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Real Name Fetcher
                  if (currentUser != null)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final name = data['name'] ?? "User";
                          return Text(
                            name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          );
                        }
                        return const Text(
                          "Loading...",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      },
                    )
                  else
                    const Text(
                      "Guest",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                  const SizedBox(height: 5),
                  Text(
                    currentUser?.email ?? "",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  _buildMenuItem(Icons.edit, "Edit Profile", () {}),
                  // Navigate to Settings Page
                  _buildMenuItem(Icons.settings, "Settings", () {
                    setState(() => _isProfileMenuOpen = false);
                    Navigator.pushNamed(context, '/settings');
                  }),
                  _buildMenuItem(Icons.help_outline, "Instructions", () {}),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Divider(color: Colors.grey[200]),
                  ),
                  _buildMenuItem(Icons.logout, "Log Out", () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  }, isLogout: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isLogout
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFFE1F5FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isLogout ? Colors.red : const Color(0xFF01579B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 20),
              Text(
                title,
                style: TextStyle(
                  color: isLogout ? Colors.red : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingUI() {
    if (!_isRecording) return const SizedBox.shrink();
    return Positioned(
      bottom: 160,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _micAnimationController,
              builder: (context, child) {
                return Icon(
                  Icons.mic,
                  size: 35,
                  color: Colors.red.withOpacity(_micAnimationController.value),
                );
              },
            ),
            const SizedBox(width: 15),
            Text(
              "Recording: $_recordingSeconds s",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildModeButton('PSL', Colors.green),
        const SizedBox(width: 10),
        _buildModeButton('ASL', Colors.blue),
      ],
    );
  }

  Widget _buildModeButton(String mode, Color color) {
    final bool isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
          _textController.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          mode,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
