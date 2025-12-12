import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../routes.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Dropdown State Variables
  String? _selectedGender;
  String? _selectedBirthYear;

  bool _isLoading = false;
  bool _isVerificationMailSent = false;
  Timer? _timer;

  // Generate list of years
  final List<String> _years = List.generate(
    DateTime.now().year - 1900 + 1,
    (index) => (1900 + index).toString(),
  ).reversed.toList();

  @override
  void dispose() {
    _timer?.cancel();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // --- LOGIC SECTION ---
  Future<void> signup() async {
    if (_selectedGender == null || _selectedBirthYear == null) {
      _showError("Please select your gender and year of birth.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      await userCred.user!.sendEmailVerification();

      setState(() {
        _isVerificationMailSent = true;
        _isLoading = false;
      });

      _showSuccess("Verification email sent! Please check your inbox.");
      _startListeningForEmailVerification(userCred.user!);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Signup failed: ${e.toString()}");
    }
  }

  void _startListeningForEmailVerification(User user) {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        timer.cancel();
        _finalizeSignup(refreshedUser.uid);
      }
    });
  }

  Future<void> _finalizeSignup(String uid) async {
    try {
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "name": nameController.text.trim(),
        "birthYear": _selectedBirthYear,
        "gender": _selectedGender,
        "email": emailController.text.trim(),
        "emailVerified": true,
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _showError("Error saving profile: ${e.toString()}");
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
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
              // 1. BACKGROUND WAVE & DECORATION (Height 35%)
              ClipPath(
                clipper: WaveClipper(),
                child: Container(
                  height: size.height * 0.35,
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
              ),

              // 2. LOGO SECTION
              Positioned(
                top: size.height * 0.05,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo.png',
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "SignSpeech",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black26,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Where Every Voice Becomes a Sign.",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. SIGNUP FORM CONTAINER (Pushed down to white area)
              Container(
                // Pushed down to 0.40 (40%) to ensure it starts in the white area below the wave (0.35)
                margin: EdgeInsets.only(top: size.height * 0.40),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "Create Account" Header
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, bottom: 15),
                      child: Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF01579B),
                        ),
                      ),
                    ),

                    // Form Fields
                    _isVerificationMailSent
                        ? _buildVerificationUI()
                        : Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  _buildSignupFields(),

                                  // Login Link Footer
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        top: 20.0,
                                        bottom: 20.0,
                                      ),
                                      child: GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: RichText(
                                          text: const TextSpan(
                                            text: "Already have an account? ",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 15,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: "Login",
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
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildSignupFields() {
    return Column(
      children: [
        _buildCreativeTextField(
          controller: nameController,
          label: "Full Name",
          icon: Icons.person_outline,
          isObscure: false,
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildCreativeDropdown(
                value: _selectedBirthYear,
                hint: "Year",
                icon: Icons.calendar_today_outlined,
                items: _years,
                onChanged: (val) => setState(() => _selectedBirthYear = val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCreativeDropdown(
                value: _selectedGender,
                hint: "Gender",
                icon: Icons.people_outline,
                items: ['Male', 'Female'],
                onChanged: (val) => setState(() => _selectedGender = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _buildCreativeTextField(
          controller: emailController,
          label: "Email",
          icon: Icons.email_outlined,
          isObscure: false,
        ),
        const SizedBox(height: 12),

        _buildCreativeTextField(
          controller: passwordController,
          label: "Password",
          icon: Icons.lock_outline,
          isObscure: true,
        ),
        const SizedBox(height: 25),

        // Gradient Button
        Container(
          width: double.infinity,
          height: 50,
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
            onPressed: _isLoading ? null : signup,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "SIGN UP",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationUI() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mark_email_read, size: 60, color: Colors.green),
          const SizedBox(height: 20),
          const Text(
            "Verify Your Email",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "We sent a link to ${emailController.text}.\nClick it to complete signup.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              FirebaseAuth.instance.currentUser?.delete();
              setState(() {
                _isVerificationMailSent = false;
                _timer?.cancel();
              });
            },
            child: const Text(
              "Cancel / Wrong Email",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // Custom Text Field
  Widget _buildCreativeTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF0288D1), size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // Custom Dropdown Field
  Widget _buildCreativeDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        menuMaxHeight: 300,
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF0288D1), size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 10,
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item, style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 60); // Reduced wave depth slightly
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 40);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 80);
    var secondEndPoint = Offset(size.width, size.height - 30);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
