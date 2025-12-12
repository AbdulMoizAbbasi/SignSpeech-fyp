import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;

  // --- LOGIC SECTION (Unchanged) ---
  Future<void> login() async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      if (userCred.user != null) {
        if (!userCred.user!.emailVerified) {
          await FirebaseAuth.instance.signOut();
          if (mounted) _showVerificationDialog(userCred.user!);
        } else {
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      _showError("Login failed: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showVerificationDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Email Not Verified"),
        content: const Text(
          "Please verify your email address before logging in.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await user.sendEmailVerification();
              Navigator.pop(context);
              _showSuccess("Verification email resent!");
            },
            child: const Text("Resend Email"),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  // --- CREATIVE UI SECTION ---

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          height: size.height,
          child: Stack(
            children: [
              // 1. BACKGROUND WAVE & DECORATION
              ClipPath(
                clipper: WaveClipper(),
                child: Container(
                  height: size.height * 0.55, // Covers top 55%
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
                      // Decorative faint circles
                      Positioned(
                        top: -50,
                        left: -50,
                        child: CircleAvatar(
                          radius: 100,
                          backgroundColor: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      Positioned(
                        bottom: 50,
                        right: -30,
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. LOGO SECTION (Centered in the wave)
              Positioned(
                top: size.height * 0.12,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(
                          0.2,
                        ), // Glass border effect
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo.png',
                            height: 110,
                            width: 110,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "SignSpeech",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            blurRadius: 15.0,
                            color: Colors.black26,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    // --- NEW TAGLINE HERE ---
                    const SizedBox(height: 5),
                    const Text(
                      "Where Every Voice Becomes a Sign.",
                      style: TextStyle(
                        fontSize:
                            13, // Size calibrated to roughly match title width
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. LOGIN FORM (Bottom Half)
              Positioned(
                top: size.height * 0.55,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20), // Spacing since text is gone
                      // Custom Styled Inputs
                      _buildCreativeTextField(
                        controller: emailController,
                        label: "Email",
                        icon: Icons.email_outlined,
                        isObscure: false,
                      ),
                      const SizedBox(height: 20),
                      _buildCreativeTextField(
                        controller: passwordController,
                        label: "Password",
                        icon: Icons.lock_outline,
                        isObscure: true,
                      ),

                      const SizedBox(height: 40),

                      // Login Button with Gradient
                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00BCD4), Color(0xFF0288D1)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0288D1).withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: _isLoading ? null : login,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "LOGIN",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                        ),
                      ),

                      const Spacer(),

                      // Footer
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 30.0),
                          child: GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/signup'),
                            child: RichText(
                              text: const TextSpan(
                                text: "New here? ",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                                children: [
                                  TextSpan(
                                    text: "Create Account",
                                    style: TextStyle(
                                      color: Color(0xFF01579B),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for the cleaner text fields
  Widget _buildCreativeTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(icon, color: const Color(0xFF0288D1)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}

// --- THE WAVE CLIPPER CLASS ---
// This creates the organic wave shape at the bottom of the blue header
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 80); // Start slightly up from bottom-left

    // Curve 1 (Goes down)
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 50);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    // Curve 2 (Goes up)
    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 100);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0); // Go to top-right
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false; // Path is static, no need to redraw constantly
  }
}
