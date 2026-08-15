import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // Vẫn giữ tạm cho ThemeProvider
import 'package:app/core/utils/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _userCtrl.dispose(); _passCtrl.dispose();
    _fadeCtrl.dispose(); _slideCtrl.dispose();
    super.dispose();
  }

  void _login() {
    context.read<AuthBloc>().add(
      LoginRequested(username: _userCtrl.text.trim(), password: _passCtrl.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/');
          }
        },
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: isDark
                  ? const LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF060913), Color(0xFF0D1429), Color(0xFF111827)],
                      stops: [0, 0.5, 1],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFFEBF0FF), Color(0xFFF0F4FF), Color(0xFFFFFFFF)],
                    ),
              ),
            ),
            // Decorative circle
            Positioned(
              top: -size.width * 0.3,
              right: -size.width * 0.2,
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.primaryBlue.withValues(alpha: isDark ? 0.25 : 0.1),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            // Theme toggle
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Consumer<ThemeProvider>(
                    builder: (_, tp, __) => IconButton(
                      onPressed: tp.toggleTheme,
                      icon: Icon(tp.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: isDark ? AppColors.gold : AppColors.primaryBlue),
                    ),
                  ),
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Hero(
                            tag: 'app_logo',
                            child: Image.asset('assets/images/Logo.png', width: 110, height: 110),
                          ),
                          const SizedBox(height: 20),
                          Text('Juss_TV',
                            style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.primaryBlue,
                              letterSpacing: 1,
                            )),
                          const SizedBox(height: 6),
                          Text('Hệ thống quản lý nội bộ',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : AppColors.primaryBlue.withValues(alpha: 0.6),
                            )),
                          const SizedBox(height: 48),
                          // Login card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark
                                ? AppColors.darkCard.withValues(alpha: 0.8)
                                : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                                  blurRadius: 30, offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                final isLoading = state is AuthLoading;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Đăng nhập', style: Theme.of(context).textTheme.headlineSmall),
                                    const SizedBox(height: 4),
                                    Text('Nhập thông tin tài khoản của bạn',
                                      style: Theme.of(context).textTheme.bodySmall),
                                    const SizedBox(height: 24),
                                    TextField(
                                      controller: _userCtrl,
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: 'Tên đăng nhập',
                                        prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    TextField(
                                      controller: _passCtrl,
                                      obscureText: _obscure,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _login(),
                                      decoration: InputDecoration(
                                        labelText: 'Mật khẩu',
                                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(() => _obscure = !_obscure),
                                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Error message
                                    if (state is AuthError)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                                        child: Text(state.message,
                                          style: const TextStyle(color: AppColors.error, fontSize: 13)),
                                      ),
                                    const SizedBox(height: 20),
                                    // Login button
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          backgroundColor: isDark ? AppColors.primaryLight : AppColors.primaryBlue,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                        child: isLoading
                                          ? const SizedBox(width: 22, height: 22,
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                          : const Text('Đăng nhập',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          // Demo hint removed
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
