import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../providers/auth_provider.dart' as ap;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _obscurePw = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit(ap.AuthProvider authProvider) async {
    final email = _emailCtrl.text.trim();
    final pw = _pwCtrl.text.trim();
    if (_isLogin) {
      await authProvider.signIn(email: email, password: pw);
    } else {
      final name = _nameCtrl.text.trim();
      await authProvider.signUp(email: email, password: pw, name: name);
      if (!mounted) return;
      // Switch to Login tab so the verification banner is immediately visible
      if (authProvider.emailNotVerified) {
        setState(() => _isLogin = true);
      }
    }
  }

  void _showForgotPasswordDialog(ap.AuthProvider auth) {
    final resetEmailCtrl =
        TextEditingController(text: _emailCtrl.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password',
            style: TextStyle(color: kWhite, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: resetEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: kWhite, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: const TextStyle(color: kGray, fontSize: 14),
            prefixIcon:
                const Icon(Icons.email_outlined, color: kGray, size: 18),
            filled: true,
            fillColor: kNavyMid,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBorderAccent),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBorderAccent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kGold),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: kGray)),
          ),
          TextButton(
            onPressed: () async {
              final email = resetEmailCtrl.text.trim();
              Navigator.pop(ctx);
              if (email.isEmpty) return;
              try {
                await auth.forgotPassword(email);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                        'Password reset email sent! Check your inbox and spam folder.'),
                    backgroundColor: Colors.green.shade700,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: kRed,
                  ),
                );
              }
            },
            child: const Text('Send Reset Email',
                style:
                    TextStyle(color: kGold, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kGray, fontSize: 14),
      prefixIcon: Icon(icon, color: kGray, size: 18),
      filled: true,
      fillColor: kNavyMid,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorderAccent),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorderAccent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kGold),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ap.AuthProvider>();
    final isLoading = auth.status == ap.AuthStatus.loading;

    return Scaffold(
      backgroundColor: kNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/image.png',
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Kigali City Services',
                style: TextStyle(
                  color: kWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Your guide to services & places in Kigali',
                style: TextStyle(color: kGray, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kBorder),
                ),
                child: Column(
                  children: [
                    // Tab toggle
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: kNavyMid,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: ['Login', 'Sign Up'].map((t) {
                          final isActive =
                              _isLogin ? t == 'Login' : t == 'Sign Up';
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _isLogin = t == 'Login');
                                auth.clearError();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      isActive ? kGold : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    color: isActive ? kNavy : kGray,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!_isLogin) ...[
                      TextField(
                        controller: _nameCtrl,
                        style: const TextStyle(color: kWhite, fontSize: 14),
                        decoration: _inputDeco('Full Name', Icons.person_outline),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: kWhite, fontSize: 14),
                      decoration:
                          _inputDeco('Email Address', Icons.email_outlined),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _pwCtrl,
                      obscureText: _obscurePw,
                      style: const TextStyle(color: kWhite, fontSize: 14),
                      decoration: _inputDeco(
                              'Password', Icons.lock_outline)
                          .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePw
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: kGray,
                            size: 18,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePw = !_obscurePw),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (auth.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kRed.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: kRed, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                auth.errorMessage!,
                                style: const TextStyle(
                                    color: kRed, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (auth.emailNotVerified) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kGold.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email not verified. Please check your inbox.',
                              style: TextStyle(color: kGold, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    try {
                                      await auth.resendVerificationEmail();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                              'Verification email sent! Check your inbox and spam folder.'),
                                          backgroundColor: Colors.green.shade700,
                                        ),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Could not send email: ${e.toString()}'),
                                          backgroundColor: kRed,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    'Resend email',
                                    style: TextStyle(
                                      color: kGold,
                                      fontSize: 12,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () async {
                                    await auth.checkEmailVerified();
                                    if (!context.mounted) return;
                                    if (auth.emailNotVerified) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Email not verified yet. Check your inbox.'),
                                          backgroundColor: kRed,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    'I\'ve verified ✓',
                                    style: TextStyle(
                                      color: kGold,
                                      fontSize: 12,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => _submit(auth),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGold,
                          foregroundColor: kNavy,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: kNavy, strokeWidth: 2),
                              )
                            : Text(
                                _isLogin ? 'Sign In' : 'Create Account',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                      ),
                    ),
                    if (_isLogin) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _showForgotPasswordDialog(auth),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: kGold,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
