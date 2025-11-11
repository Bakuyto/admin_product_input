// ─────────────────────────────────────────────────────────────────────────────
//  login_view.dart – Premium Glassmorphic Login (no shimmer)
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_flutter_app/models/pub_var.dart' as pub_var;
import '../controllers/auth_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with TickerProviderStateMixin {
  final AuthController _authController = AuthController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  // ────── DESIGN CONSTANTS ──────
  static const Color _accent = Colors.cyan;
  static const String _logoUrl =
      'https://app.pacific.com.kh/pacific/assets/assets/ico/ped-logo.png'; // Replace

  late final AnimationController _loadCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _waveCtrl;

  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _waveAnim;

  @override
  void initState() {
    super.initState();
    _authController.init();
    _loadSavedCredentials();

    // Page load animation
    _loadCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _loadCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _loadCtrl, curve: Curves.easeOutBack));
    _loadCtrl.forward();

    // Logo pulse
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Background wave
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _waveAnim = Tween<double>(begin: 0, end: 1).animate(_waveCtrl);
  }

  Future<void> _loadSavedCredentials() async {
    final savedUsername = await _authController.getSavedUsername();
    final rememberMe = await _authController.isRememberMeEnabled();

    if (mounted) {
      setState(() {
        _rememberMe = rememberMe;
        if (savedUsername != null) {
          _usernameCtrl.text = savedUsername;
        }
      });
    }
  }

  @override
  void dispose() {
    _authController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _loadCtrl.dispose();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  // ────── LOGIN LOGIC ──────
  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authController.login(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text,
        remember: _rememberMe,
      );

      if (!mounted) return;

      if (result['success']) {
        // ✅ SAVE USER ROLE GLOBALLY
        pub_var.userRole = result['user']['user_role'].toString();

        // ✅ NAVIGATE
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        _showError(result['message'] ?? 'Invalid credentials');
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg, style: GoogleFonts.poppins())),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ────── ANIMATED BACKGROUND ──────
          _AnimatedGradientBackground(waveAnim: _waveAnim),

          // ────── MAIN CONTENT ──────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: _buildGlassCard(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────── GLASSMORPHIC CARD ──────
  Widget _buildGlassCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.35),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 20),
                  _buildTitle(),
                  const SizedBox(height: 40),
                  _buildUsernameField(),
                  const SizedBox(height: 20),
                  _buildPasswordField(),
                  const SizedBox(height: 20),
                  _buildRememberMeCheckbox(),
                  const SizedBox(height: 40),
                  _buildLoginButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ────── LOGO WITH PULSE ──────
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final pulse = 1.0 + (_pulseCtrl.value * 0.1);
        final glow = _pulseCtrl.value * 0.6;

        return Transform.scale(
          scale: pulse,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _accent.withOpacity(0.3 + glow),
                  _accent.withOpacity(0.1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.4 + glow),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: _logoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: Colors.white.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: _accent,
                      strokeWidth: 3,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.business,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ────── TITLE ──────
  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Welcome Back',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to continue',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ────── USERNAME FIELD ──────
  Widget _buildUsernameField() {
    return _AnimatedInput(
      controller: _usernameCtrl,
      focusNode: _usernameFocus,
      label: 'Username or Email',
      icon: Icons.person_outline_rounded,
      keyboardType: TextInputType.emailAddress,
      validator: (v) =>
          v?.trim().isEmpty == true ? 'Enter your username' : null,
    );
  }

  // ────── PASSWORD FIELD ──────
  Widget _buildPasswordField() {
    return _AnimatedInput(
      controller: _passwordCtrl,
      focusNode: _passwordFocus,
      label: 'Password',
      icon: Icons.lock_outline_rounded,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onSubmitted: () => _login(), // Fixed: VoidCallback
      validator: (v) => v?.isEmpty == true ? 'Enter your password' : null,
      suffix: IconButton(
        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        color: _passwordFocus.hasFocus ? _accent : Colors.grey.shade600,
      ),
    );
  }

  // ────── REMEMBER ME CHECKBOX ──────
  Widget _buildRememberMeCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value ?? false;
            });
          },
          activeColor: _accent,
          checkColor: Colors.white,
        ),
        Text(
          'Remember Me',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ────── LOGIN BUTTON ──────
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          elevation: 12,
          shadowColor: _accent.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isLoading
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Text(
                  'SIGN IN',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
        ),
      ),
    );
  }
}

// ────── REUSABLE ANIMATED INPUT ──────
class _AnimatedInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final VoidCallback? onSubmitted; // Fixed type
  final Widget? suffix;

  const _AnimatedInput({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onSubmitted,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final hasFocus = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: _LoginViewState._accent.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onFieldSubmitted: (_) => onSubmitted?.call(), // Fixed
        style: GoogleFonts.poppins(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: hasFocus ? _LoginViewState._accent : Colors.black54,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            icon,
            color: hasFocus ? _LoginViewState._accent : Colors.black54,
          ),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white.withOpacity(0.7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: _LoginViewState._accent, width: 2.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 20,
          ),
        ),
      ),
    );
  }
}

// ────── ANIMATED GRADIENT BACKGROUND ──────
class _AnimatedGradientBackground extends StatelessWidget {
  final Animation<double> waveAnim;

  const _AnimatedGradientBackground({required this.waveAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: waveAnim,
      builder: (context, child) {
        final offset = waveAnim.value * 2 * 3.14159;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.cyan.shade100.withOpacity(0.3),
                Colors.cyan.shade50.withOpacity(0.5),
                Colors.white.withOpacity(0.9),
              ],
              stops: [0.0, 0.5 + (0.3 * (offset / 6.28)), 1.0],
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: Container(color: Colors.transparent),
          ),
        );
      },
    );
  }
}
