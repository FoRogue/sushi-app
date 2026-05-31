import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../data/auth_repository.dart';
import 'widgets/auth_background.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  static const _accent = Color(0xFFD9381E);
  static const _textDark = Color(0xFF222222);
  static const _bgColor = Color(0xFFF9F6F0);

  int _roleIndex = 0;

  final _formKey = GlobalKey<FormState>();
  final _field1Ctrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  late AuthRepository _authRepo;
  late AnimationController _formAnim;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;

  late AnimationController _bgAnim;

  @override
  void initState() {
    super.initState();

    _authRepo = AuthRepository(ApiClient.create());

    _formAnim = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );
    _formFade = CurvedAnimation(parent: _formAnim, curve: Curves.easeOut);
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _formAnim, curve: Curves.easeOutCubic));

    _bgAnim = AnimationController(
      duration: const Duration(seconds: 9),
      vsync: this,
    )..repeat(reverse: true);

    _formAnim.forward();
  }

  @override
  void dispose() {
    _formAnim.dispose();
    _bgAnim.dispose();
    _field1Ctrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  static const _labels = ['Номер телефона', 'Код транспорта', 'Адрес магазина'];
  static const _hints = ['+7 (999) 123-45-67', 'А123БВ777', 'г. Москва, ул. Пушкина, д. 1'];
  static const _icons = [
    Icons.phone_outlined,
    Icons.directions_car_outlined,
    Icons.location_on_outlined,
  ];

  void _switchRole(int i) {
    if (_roleIndex == i) return;
    _formAnim.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _roleIndex = i;
        _field1Ctrl.clear();
        _passwordCtrl.clear();
        _error = null;
      });
      _formAnim.forward();
    });
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });

    try {
      switch (_roleIndex) {
        case 0:
          await _authRepo.loginCustomer(
            phone: _field1Ctrl.text.trim(),
            password: _passwordCtrl.text,
          );
        case 1:
          await _authRepo.loginCourier(
            vehicleCode: _field1Ctrl.text.trim(),
            password: _passwordCtrl.text,
          );
        case 2:
          await _authRepo.loginShop(
            address: _field1Ctrl.text.trim(),
            password: _passwordCtrl.text,
          );
      }
      if (!mounted) return;
      final roleStr = ['customer', 'courier', 'shop'][_roleIndex];
      await ref.read(authProvider.notifier).onLogin(roleStr);
      if (!mounted) return;
      context.go(switch (_roleIndex) {
        1 => '/courier/orders',
        2 => '/shop/orders',
        _ => '/customer/catalog',
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _error = _dioError(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Произошла ошибка. Попробуйте позже.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goToRegister() async {
    context.push('/register');
  }

  String _dioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Нет соединения с сервером';
    }
    return switch (e.response?.statusCode) {
      400 => 'Проверьте правильность введённых данных',
      401 => 'Неверные данные для входа',
      500 => 'Ошибка сервера. Попробуйте позже.',
      _ => 'Произошла ошибка. Попробуйте позже.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Stack(
          children: [
            AuthBackground(controller: _bgAnim),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 44,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _buildCard(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.07),
            blurRadius: 60,
            spreadRadius: -5,
            offset: const Offset(0, 30),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(28, 42, 28, 38),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildRoleTabs(),
          const SizedBox(height: 28),
          _buildForm(),
          if (_error != null) ...[
            const SizedBox(height: 14),
            _buildError(),
          ],
          const SizedBox(height: 26),
          _buildButton(),
          const SizedBox(height: 20),
          _buildRegisterLink(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEA4820), Color(0xFFB42415)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(0.42),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: _accent.withOpacity(0.18),
                blurRadius: 44,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: const Center(
            child: Text('🍱', style: TextStyle(fontSize: 38)),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Суши Дом',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: _textDark,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Войдите, чтобы продолжить',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: _textDark.withOpacity(0.42),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleTabs() {
    const roles = [
      (icon: Icons.shopping_bag_outlined, label: 'Покупатель'),
      (icon: Icons.delivery_dining_outlined, label: 'Курьер'),
      (icon: Icons.store_outlined, label: 'Магазин'),
    ];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.07),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: List.generate(roles.length, (i) {
          final sel = _roleIndex == i;
          final role = roles[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => _switchRole(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? _accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: _accent.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      role.icon,
                      size: 18,
                      color: sel
                          ? Colors.white
                          : _textDark.withOpacity(0.38),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            sel ? FontWeight.w600 : FontWeight.w500,
                        color: sel
                            ? Colors.white
                            : _textDark.withOpacity(0.38),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildForm() {
    return FadeTransition(
      opacity: _formFade,
      child: SlideTransition(
        position: _formSlide,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInput(
                ctrl: _field1Ctrl,
                label: _labels[_roleIndex],
                hint: _hints[_roleIndex],
                icon: _icons[_roleIndex],
                validator: (v) =>
                    v == null || v.isEmpty ? 'Заполните поле' : null,
              ),
              const SizedBox(height: 12),
              _buildInput(
                ctrl: _passwordCtrl,
                label: 'Пароль',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 19,
                    color: _accent,
                  ),
                  splashRadius: 18,
                ),
                validator: (v) =>
                    v == null || v.length < 4 ? 'Минимум 4 символа' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(
        color: _textDark,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: _textDark.withOpacity(0.28),
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: _textDark.withOpacity(0.42),
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: _accent,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: _accent, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 52),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.72),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.95),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _accent, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withOpacity(0.22), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: _accent, size: 16),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: _accent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Нет аккаунта?  ',
          style: TextStyle(
            color: _textDark.withOpacity(0.45),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: _goToRegister,
          child: const Text(
            'Зарегистрироваться',
            style: TextStyle(
              color: _accent,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton() {
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _loading
              ? null
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFEA4520), Color(0xFFB82210)],
                ),
          color: _loading ? Colors.black12 : null,
          borderRadius: BorderRadius.circular(17),
          boxShadow: _loading
              ? null
              : [
                  BoxShadow(
                    color: _accent.withOpacity(0.48),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _loading ? null : _login,
            borderRadius: BorderRadius.circular(17),
            splashColor: Colors.white.withOpacity(0.12),
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Войти',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

