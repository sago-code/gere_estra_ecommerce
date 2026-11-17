import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authService,
    required this.storage,
  });

  final AuthService authService;
  final StorageService storage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await widget.authService.login(
        correo: _correoController.text.trim(),
        password: _passwordController.text,
      );

      await widget.storage.saveSession(
        token: response.accessToken,
        nombre: response.usuario.nombreCompleto,
        correo: response.usuario.correo,
        rol: response.usuario.rol,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/');
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Ocurrió un error inesperado.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: isWide ? _buildWideLayout(context) : _buildMobileLayout(context),
      ),
    );
  }

  /// Layout de dos columnas para web/escritorio.
  Widget _buildWideLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 5, child: _buildBrandPanel()),
        Expanded(flex: 4, child: _buildFormPanel()),
      ],
    );
  }

  /// Layout de una columna para móvil.
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBrandHeader(),
          const SizedBox(height: 32),
          _buildFormCard(),
        ],
      ),
    );
  }

  /// Panel lateral de marca (negro con acentos rojo y amarillo).
  Widget _buildBrandPanel() {
    return Container(
      color: AppColors.black,
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.storefront,
              color: AppColors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Control de Ventas\ny Entregas',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 4,
            width: 80,
            color: AppColors.yellow,
          ),
          const SizedBox(height: 24),
          const Text(
            'Panel de gestión estratégica para e-commerce. '
            'Visualiza tus KPIs de ventas, ciclo de entrega y productos '
            'más vendidos en tiempo real.',
            style: TextStyle(
              color: AppColors.whiteSoft,
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          _buildFeatureRow(Icons.trending_up, 'Ticket promedio'),
          _buildFeatureRow(Icons.local_shipping, 'Ciclo de entrega'),
          _buildFeatureRow(Icons.inventory_2, 'Productos más vendidos'),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.yellow, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Encabezado compacto para móvil.
  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.storefront,
            color: AppColors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Control de Ventas',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 3,
          width: 56,
          color: AppColors.yellow,
        ),
      ],
    );
  }

  /// Panel blanco con el formulario (web/escritorio).
  Widget _buildFormPanel() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _buildFormContent(),
        ),
      ),
    );
  }

  /// Tarjeta del formulario (móvil).
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: _buildFormContent(),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Iniciar sesión',
            style: TextStyle(
              color: AppColors.black,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa tus credenciales de administrador',
            style: TextStyle(
              color: AppColors.gray,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _correoController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email_outlined, color: AppColors.gray),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa tu correo';
              }
              if (!value.contains('@')) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon:
                  const Icon(Icons.lock_outline, color: AppColors.gray),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.gray,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa tu contraseña';
              }
              return null;
            },
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.redDark,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Text('INGRESAR'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 3,
                width: 24,
                color: AppColors.yellow,
              ),
              const SizedBox(width: 8),
              const Text(
                'Solo administradores',
                style: TextStyle(
                  color: AppColors.gray,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 3,
                width: 24,
                color: AppColors.yellow,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
