import 'dart:ui';
import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart'; // Assumed to exist

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with TickerProviderStateMixin {
  final AuthController _authController = AuthController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _isLoading = false;

  // Configuration Constants
  static const Color _accentColor = Colors.cyan; // Your new main color
  static const String _logoUrl =
      'https://app.pacific.com.kh/pacific/assets/assets/ico/ped-logo.png'; // <-- 🚨 REPLACE THIS WITH YOUR LOGO'S URL

  late AnimationController _loadController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _authController.init();

    // Initial Load Animation (Fade and Scale in)
    _loadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _loadController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _loadController, curve: Curves.easeOutBack),
    );
    _loadController.forward();

    // Logo Pulse Animation (Subtle continuous effect)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _authController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _loadController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authController.login(
        _usernameController.text,
        _passwordController.text,
      );
      if (result['success']) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: ${result['message']}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- MODIFICATION 1: Set background to solid color ---
      backgroundColor: Colors.white, // Set Scaffold background to white
      resizeToAvoidBottomInset: true,
      body: Container(
        // Add a subtle top-to-bottom cyan gradient to the body for style
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.cyan.shade200.withOpacity(0.3), // Subtle cyan at the top
              Colors.cyan.shade50.withOpacity(0.7),  // Lighter cyan in the middle
              Colors.white.withOpacity(0.9),         // Soft white at the bottom
            ],
            stops: const [0.0, 0.5, 1.0], 
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildLoginCard(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the glassmorphism-styled login card.
  Widget _buildLoginCard(BuildContext context) {
    const Color accentColor = _accentColor;

    return Container(
      // Outer container styling for shadow and border
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          // Lighter shadow for a brighter background
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
        // The card border now contrasts with the white background
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          // Apply blur effect
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            // --- MODIFICATION 2: Adjust opacity to make the 'glass' visible on white ---
            color: Colors.white.withOpacity(
              0.4,
            ), // Higher opacity for visibility on white
            padding: const EdgeInsets.all(30.0),
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- MODIFICATION 3: Logo Image.network and pulse animation ---
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.08),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor.withOpacity(0.1),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(
                                  0.5 * _pulseController.value,
                                ),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              _logoUrl,
                              fit: BoxFit.cover,
                              // Use a placeholder/error builder for safety
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        color: accentColor,
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Colors.red,
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // --- Title ---
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.black87, // Dark text for white background
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to access your account',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black54, // Lighter dark text
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // --- Fields ---
                  _buildTextField(
                    controller: _usernameController,
                    focusNode: _usernameFocus,
                    label: 'Username',
                    icon: Icons.person_outline,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 40),
                  // --- Login Button ---
                  _LoginButton(isLoading: _isLoading, onPressed: _handleLogin),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Refactored TextField with focus animation, validation, and glassmorphism styling
  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    Function(String)? onFieldSubmitted,
  }) {
    const Color accentColor = _accentColor;
    // Input fill color is still white with some transparency
    const Color inputFillColor = Color(0x10FFFFFF);

    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        final hasFocus = focusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: hasFocus
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        0.05,
                      ), // Subtle shadow when not focused
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            // --- MODIFICATION 4: Input text color is dark ---
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your $label.';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: label,
              // --- MODIFICATION 5: Label and Icon color adjusted for light background ---
              labelStyle: TextStyle(
                color: hasFocus ? accentColor : Colors.black54,
              ),
              prefixIcon: Icon(
                icon,
                color: hasFocus ? accentColor : Colors.black54,
              ),
              filled: true,
              fillColor: inputFillColor,
              // Border styles
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: accentColor, // Cyan border
                  width: 3.0,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 3),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 20,
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Separate Login Button Widget ---
class _LoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoginButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    const Color accentColor =
        _LoginViewState._accentColor; // Use the defined accent color

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor, // Cyan background
        foregroundColor: Colors.white, // White text/icon for contrast
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 10,
        shadowColor: accentColor.withOpacity(0.6),
        minimumSize: const Size(double.infinity, 65),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: isLoading
            ? const SizedBox(
                key: ValueKey('loading'),
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white, // White progress indicator for contrast
                  strokeWidth: 3.5,
                ),
              )
            : const Text(
                'SIGN IN',
                key: ValueKey('text'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
      ),
    );
  }
}
