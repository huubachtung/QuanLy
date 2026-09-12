import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // Vẫn giữ tạm cho ThemeProvider
import 'package:app/core/utils/app_colors.dart';
import 'package:app/core/utils/app_tokens.dart';
import 'package:app/core/utils/vietnamese_to_telex_formatter.dart';
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
    _fadeCtrl = AnimationController(vsync: this, duration: AppTokens.animNormal);
    _slideCtrl = AnimationController(vsync: this, duration: AppTokens.animNormal);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutQuad);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutQuad));
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
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
                  padding: const EdgeInsets.all(AppTokens.s16),
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
                  padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
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
                            child: Image.asset('assets/images/Logo.png', width: 96, height: 96),
                          ),
                          const SizedBox(height: AppTokens.s16),
                          Text('Juss_TV',
                            style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.primaryBlue,
                              letterSpacing: 0.5,
                            )),
                          const SizedBox(height: AppTokens.s4),
                          Text('Hệ thống quản lý nội bộ',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : AppColors.primaryBlue.withValues(alpha: 0.6),
                            )),
                          const SizedBox(height: AppTokens.s32),
                          // Login card
                          Container(
                            padding: const EdgeInsets.all(AppTokens.s24),
                            decoration: BoxDecoration(
                              color: isDark
                                ? AppColors.darkCard
                                : Colors.white,
                              borderRadius: BorderRadius.circular(AppTokens.rCard),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                width: 1.0,
                              ),
                            ),
                            child: BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                final isLoading = state is AuthLoading;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Đăng nhập',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      )),
                                    const SizedBox(height: AppTokens.s4),
                                    Text('Nhập thông tin tài khoản của bạn',
                                      style: Theme.of(context).textTheme.bodySmall),
                                    const SizedBox(height: AppTokens.s24),
                                    TextField(
                                      controller: _userCtrl,
                                      keyboardType: TextInputType.text,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      inputFormatters: [VietnameseToTelexFormatter()],
                                      textInputAction: TextInputAction.next,
                                      onChanged: (val) {
                                        final telex = vietnameseToTelex(val);
                                        if (telex != val) {
                                          _userCtrl.value = TextEditingValue(
                                            text: telex,
                                            selection: TextSelection.collapsed(offset: telex.length),
                                          );
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        labelText: 'Tên đăng nhập',
                                        prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                                      ),
                                    ),
                                    const SizedBox(height: AppTokens.s12),
                                    TextField(
                                      controller: _passCtrl,
                                      obscureText: _obscure,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      inputFormatters: [VietnameseToTelexFormatter()],
                                      textInputAction: TextInputAction.done,
                                      onChanged: (val) {
                                        final telex = vietnameseToTelex(val);
                                        if (telex != val) {
                                          _passCtrl.value = TextEditingValue(
                                            text: telex,
                                            selection: TextSelection.collapsed(offset: telex.length),
                                          );
                                        }
                                      },
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
                                    const SizedBox(height: AppTokens.s8),
                                    // Error or session expired message
                                    if (state is AuthError) ...[
                                      Padding(
                                        padding: const EdgeInsets.only(top: AppTokens.s8, bottom: AppTokens.s4),
                                        child: Text(state.message,
                                          style: const TextStyle(color: AppColors.error, fontSize: 12)),
                                      ),
                                    ] else if (state is AuthUnauthenticated && state.message != null) ...[
                                      Container(
                                        margin: const EdgeInsets.only(top: AppTokens.s8, bottom: AppTokens.s4),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                state.message!,
                                                style: const TextStyle(
                                                  color: AppColors.warning,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: AppTokens.s16),
                                    // Login button
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: AppTokens.s12),
                                          backgroundColor: isDark ? AppColors.primaryLight : AppColors.primaryBlue,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(AppTokens.rInput),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: isLoading
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
                                            )
                                          : const Text(
                                              'Đăng nhập',
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                            ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
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
