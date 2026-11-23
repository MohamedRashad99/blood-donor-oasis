import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (context.read<AuthProvider>().isLoading) return;
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.login(
        _usernameController.text,
        _passwordController.text,
      );
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'فشل تسجيل الدخول، تحقق من البيانات',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    fillColor: AppColors.bgSurface,
    prefixIcon: Icon(icon, size: 21, color: AppColors.textSecondary),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );

  Widget _form(bool compact) {
    final loading = context.watch<AuthProvider>().isLoading;
    return Padding(
      padding: EdgeInsets.all(compact ? 24 : 40),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'أهلاً بعودتك',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'سجّل دخولك لمتابعة رحلة العطاء.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),
              const Text(
                'اسم المستخدم',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const ValueKey('login-username'),
                controller: _usernameController,
                autofillHints: const [AutofillHints.username],
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: _decoration(
                  'أدخل اسم المستخدم',
                  Icons.person_outline_rounded,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'يرجى إدخال اسم المستخدم'
                    : null,
              ),
              const SizedBox(height: 20),
              const Text(
                'كلمة المرور',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const ValueKey('login-password'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                onFieldSubmitted: (_) => _handleLogin(),
                decoration:
                    _decoration(
                      'أدخل كلمة المرور',
                      Icons.lock_outline_rounded,
                    ).copyWith(
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'إظهار كلمة المرور'
                            : 'إخفاء كلمة المرور',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 21,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'يرجى إدخال كلمة المرور'
                    : null,
              ),
              const SizedBox(height: 28),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: ElevatedButton(
                  key: const ValueKey('login-submit'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: loading ? null : _handleLogin,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'تسجيل الدخول',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Icon(Icons.arrow_back_rounded, size: 20),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'نسخة تجريبية بتسجيل دخول محلي، وليست حماية فعلية لبيانات المتبرعين.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.7,
                          color: AppColors.textSecondary,
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

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFCF7F7),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 850;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: desktop ? 40 : 20,
                    vertical: desktop ? 40 : 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!desktop) ...[
                          const _BrandHeader(),
                          const SizedBox(height: 24),
                        ],
                        Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(
                              desktop ? 28 : 24,
                            ),
                            border: Border.all(color: const Color(0xFFF0E4E4)),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryRedDark.withValues(
                                  alpha: 0.05,
                                ),
                                blurRadius: 48,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: desktop
                              ? IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Expanded(child: _StoryPanel()),
                                      Expanded(child: _form(false)),
                                    ],
                                  ),
                                )
                              : _form(true),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          AppConstants.supervisor,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          AppConstants.orgLocation,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primaryRed,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.bloodtype_rounded,
          color: Colors.white,
          size: 34,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        AppConstants.orgName,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 3),
      const Text(
        AppConstants.appTitle,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.primaryRed,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _StoryPanel extends StatelessWidget {
  const _StoryPanel();

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF9D1925), AppColors.primaryRed, Color(0xFFDB4545)],
      ),
    ),
    padding: const EdgeInsets.all(36),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.bloodtype_rounded, color: Colors.white, size: 34),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                AppConstants.orgName,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.7,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 216,
                  height: 216,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -0.12,
                  child: Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bloodtype_rounded,
                      size: 76,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 36,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEEE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 25,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'نقطة دم\nتساوي حياة',
          style: TextStyle(
            fontSize: 36,
            height: 1.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'معاً لتنظيم التبرع بالدم،\nوربط العطاء بمن يحتاجه.',
          style: TextStyle(fontSize: 14, height: 1.9, color: Color(0xFFFFE1E1)),
        ),
        const Spacer(),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.volunteer_activism_outlined,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppConstants.appTitle,
                  style: TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
