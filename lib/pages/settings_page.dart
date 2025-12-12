import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // --- State Variables (In a real app, use SharedPreferences) ---
  bool _isDarkMode = false;
  bool _autoPlay = true;
  double _playbackSpeed = 1.0; // 1.0 is normal speed
  double _fontSize = 16.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      body: Stack(
        children: [
          // 1. BACKGROUND HEADER (Matches your App Theme)
          Container(
            height: size.height * 0.25,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF01579B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Back Button
                  Positioned(
                    top: 10,
                    left: 10,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  // Title
                  const Center(
                    child: Text(
                      "Settings",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. SETTINGS LIST
          Container(
            margin: EdgeInsets.only(top: size.height * 0.20),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // --- SECTION 1: VIDEO & PLAYBACK ---
                  _buildSectionHeader("Video Preferences"),
                  _buildCard(
                    children: [
                      // Playback Speed Slider
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Playback Speed",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "${_playbackSpeed}x",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF01579B),
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _playbackSpeed,
                              min: 0.5,
                              max: 2.0,
                              divisions: 3, // 0.5, 1.0, 1.5, 2.0
                              activeColor: const Color(0xFF00BCD4),
                              inactiveColor: Colors.grey[300],
                              onChanged: (val) {
                                setState(() => _playbackSpeed = val);
                                // TODO: Save this value to SharedPreferences
                              },
                            ),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Slow (0.5x)",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  "Fast (2.0x)",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Auto Play Toggle
                      SwitchListTile(
                        activeColor: const Color(0xFF00BCD4),
                        title: const Text(
                          "Auto-Play Videos",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text(
                          "Play videos automatically when loaded",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        value: _autoPlay,
                        onChanged: (val) => setState(() => _autoPlay = val),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // --- SECTION 2: APPEARANCE ---
                  _buildSectionHeader("Appearance"),
                  _buildCard(
                    children: [
                      // Dark Mode Toggle
                      SwitchListTile(
                        activeColor: const Color(0xFF00BCD4),
                        secondary: Icon(
                          Icons.dark_mode,
                          color: _isDarkMode ? Colors.purple : Colors.grey,
                        ),
                        title: const Text(
                          "Dark Mode",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: _isDarkMode,
                        onChanged: (val) {
                          setState(() => _isDarkMode = val);
                          // Note: Real Dark Mode requires changing MaterialApp theme
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Theme saved (Requires App Restart to fully apply)",
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      // Text Size
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Text Size",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => setState(() {
                                    if (_fontSize > 12) _fontSize--;
                                  }),
                                ),
                                Text(
                                  "${_fontSize.toInt()}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Color(0xFF00BCD4),
                                  ),
                                  onPressed: () => setState(() {
                                    if (_fontSize < 24) _fontSize++;
                                  }),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // --- SECTION 3: ACCOUNT & PRIVACY ---
                  _buildSectionHeader("Account"),
                  _buildCard(
                    children: [
                      _buildClickableTile(
                        Icons.lock_outline,
                        "Change Password",
                        () {},
                      ),
                      const Divider(height: 1),
                      _buildClickableTile(
                        Icons.info_outline,
                        "About SignSpeech",
                        () {
                          showAboutDialog(
                            context: context,
                            applicationName: "SignSpeech",
                            applicationVersion: "1.0.0",
                            applicationIcon: Image.asset(
                              "assets/logo.png",
                              width: 50,
                              height: 50,
                            ),
                            children: [
                              const Text("Translating voice to sign language."),
                            ],
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets for Clean Code ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildClickableTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.1)
              : const Color(0xFFE0F7FA),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : const Color(0xFF00BCD4),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
