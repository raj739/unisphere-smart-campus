import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  String? errorMessage;

  String selectedRole = 'Student';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();

    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      setState(() {
        errorMessage = 'Please enter your email and password.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await AuthService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      final role = response['role']?.toString().toLowerCase();

      if (role == 'student') {
        Navigator.pushReplacementNamed(context, '/app');
      } else if (role == 'parent') {
        Navigator.pushReplacementNamed(context, '/parent');
      } else if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        setState(() {
          errorMessage = 'Unsupported account role.';
        });
      }
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Unable to sign in. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _selectRole(String role) {
    setState(() {
      selectedRole = role;
      errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              color: const Color(0xFF172554),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),

                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'UNISPHERE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'One Identity.\n'
                        'One Campus.\n'
                        'One Intelligent Student Journey.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'A unified digital campus connecting academics, '
                        'student services, certificates and intelligent assistance.',
                        style: TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 48),

                      const Text(
                        'SECURE  •  UNIFIED  •  INTELLIGENT',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 70,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Sign in to your university account',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF64748B),
                        ),
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        'Sign in as',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),

                      const SizedBox(height: 9),

                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment<String>(
                              value: 'Student',
                              icon: Icon(Icons.school_outlined),
                              label: Text('Student'),
                            ),
                            ButtonSegment<String>(
                              value: 'Parent',
                              icon: Icon(Icons.family_restroom_outlined),
                              label: Text('Parent'),
                            ),
                            ButtonSegment<String>(
                              value: 'Admin',
                              icon: Icon(Icons.admin_panel_settings_outlined),
                              label: Text('Admin'),
                            ),
                          ],
                          selected: {selectedRole},
                          onSelectionChanged: isLoading
                              ? null
                              : (selection) {
                                  _selectRole(selection.first);
                                },
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'University Email',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),

                      const SizedBox(height: 9),

                      TextField(
                        controller: emailController,
                        enabled: !isLoading,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'Enter your university email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF3730A3),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),

                      const SizedBox(height: 9),

                      TextField(
                        controller: passwordController,
                        enabled: !isLoading,
                        obscureText: obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!isLoading) {
                            _signIn();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: isLoading
                                ? null
                                : () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF3730A3),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading ? null : () {},
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: Color(0xFF3730A3),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      if (errorMessage != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 19,
                                color: Color(0xFFDC2626),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFB91C1C),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3730A3),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF818CF8),
                            disabledForegroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Sign In as $selectedRole  →',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      Center(
                        child: Text(
                          'Student  •  Parent  •  Administrator',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
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
    );
  }
}
