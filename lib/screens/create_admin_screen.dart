import 'package:flutter/material.dart';
import '../services/usuario_service.dart';
import '../theme/app_theme.dart';

/// Pantalla para crear un nuevo usuario administrador.
class CreateAdminScreen extends StatefulWidget {
  const CreateAdminScreen({super.key});

  @override
  State<CreateAdminScreen> createState() => _CreateAdminScreenState();
}

class _CreateAdminScreenState extends State<CreateAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final UsuarioService _service = UsuarioService();

  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  List<Ciudad> _ciudades = [];
  int? _ciudadSeleccionada;
  bool _loadingCiudades = true;
  bool _submitting = false;
  String? _errorMessage;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _loadCiudades();
  }

  @override
  void dispose() {
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCiudades() async {
    try {
      final ciudades = await _service.getCiudades();
      if (mounted) {
        setState(() {
          _ciudades = ciudades;
          _loadingCiudades = false;
          if (ciudades.isNotEmpty) _ciudadSeleccionada = ciudades.first.id;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loadingCiudades = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ciudadSeleccionada == null) {
      setState(() => _errorMessage = 'Selecciona una ciudad.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _success = false;
    });

    try {
      await _service.createAdmin(
        nombres: _nombresCtrl.text.trim(),
        apellidos: _apellidosCtrl.text.trim(),
        ciudadId: _ciudadSeleccionada!,
        telefono: int.tryParse(_telefonoCtrl.text.trim()) ?? 0,
        correo: _correoCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (mounted) {
        setState(() {
          _success = true;
          _submitting = false;
        });
        _formKey.currentState!.reset();
        _nombresCtrl.clear();
        _apellidosCtrl.clear();
        _telefonoCtrl.clear();
        _correoCtrl.clear();
        _passwordCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Administrador'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  if (_success) _buildSuccessBanner(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    _buildErrorBanner(_errorMessage!),
                  ],
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _nombresCtrl,
                    label: 'Nombres',
                    icon: Icons.person,
                    validator: (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Ingresa los nombres'
                            : null,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _apellidosCtrl,
                    label: 'Apellidos',
                    icon: Icons.person_outline,
                    validator: (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Ingresa los apellidos'
                            : null,
                  ),
                  const SizedBox(height: 14),
                  _buildCiudadDropdown(),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _telefonoCtrl,
                    label: 'Teléfono',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ingresa el teléfono';
                      }
                      if (int.tryParse(v.trim()) == null) {
                        return 'Solo números';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _correoCtrl,
                    label: 'Correo electrónico',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ingresa el correo';
                      }
                      if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$')
                          .hasMatch(v.trim())) {
                        return 'Correo inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _passwordCtrl,
                    label: 'Contraseña',
                    icon: Icons.lock,
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Ingresa la contraseña';
                      }
                      if (v.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.person_add),
                    label: Text(
                      _submitting ? 'Creando...' : 'Crear Administrador',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.cancel, color: AppColors.gray),
                    label: const Text(
                      'Cancelar',
                      style: TextStyle(color: AppColors.gray),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: AppColors.gray),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.admin_panel_settings,
            color: AppColors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Nuevo Administrador',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Completa los datos para registrar un nuevo administrador.',
          style: TextStyle(fontSize: 13, color: AppColors.gray),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.yellow.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.yellowDark),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.black, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Administrador creado correctamente.',
              style: TextStyle(color: AppColors.black, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.red),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.red),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.gray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.gray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildCiudadDropdown() {
    if (_loadingCiudades) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.whiteSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gray),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return DropdownButtonFormField<int>(
      initialValue: _ciudadSeleccionada,
      decoration: InputDecoration(
        labelText: 'Ciudad',
        prefixIcon: const Icon(Icons.location_city, color: AppColors.red),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.gray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.gray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.red, width: 2),
        ),
      ),
      items: _ciudades
          .map(
            (c) => DropdownMenuItem<int>(
              value: c.id,
              child: Text(c.nombre),
            ),
          )
          .toList(),
      onChanged: (val) => setState(() => _ciudadSeleccionada = val),
      validator: (v) => v == null ? 'Selecciona una ciudad' : null,
    );
  }
}
