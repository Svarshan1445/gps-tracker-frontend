import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isRegisterMode = false;

  // Login Form
  final _loginFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'user_a@example.com');
  final _passwordController = TextEditingController(text: 'Password123!');
  bool _obscurePassword = true;

  // Register Form
  final _registerFormKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _regUsernameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  bool _obscureRegPassword = true;
  int _selectedAssignment = 1; // 1 to 4

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _regUsernameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  void _fillCredentials(String email, String password) {
    setState(() {
      _isRegisterMode = false;
      _emailController.text = email;
      _passwordController.text = password;
    });
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Authentication failed'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      email: _regEmailController.text,
      username: _regUsernameController.text,
      password: _regPasswordController.text,
      fullName: _fullNameController.text,
      assignedRouteId: _selectedAssignment,
      assignedVehicleId: _selectedAssignment,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registration failed'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome, ${_regUsernameController.text}! Account created successfully.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showServerSettingsDialog() {
    final urlController = TextEditingController(text: ApiConstants.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, color: Color(0xFF4338CA)),
            SizedBox(width: 8),
            Text('Backend API URL', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Default for Android: http://10.0.2.2:8000/api/v1\nDefault for Web/PC: http://localhost:8000/api/v1',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: 'Base URL',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4338CA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              ApiConstants.setBaseUrl(urlController.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('API URL updated: ${ApiConstants.baseUrl}')),
              );
            },
            child: const Text('Save URL'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF64748B)),
            tooltip: 'Server Settings',
            onPressed: _showServerSettingsDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFEEF2F6), Color(0xFFE2E8F0)],
          ),
        ),
        child: Stack(
          children: [
            // Subtle background decorative gradient circles
            Positioned(
              top: -60,
              left: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF4338CA).withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF06B6D4).withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main Center Content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Brand & Logo
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF3B82F6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4338CA).withOpacity(0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 38),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'TransitTrack Live',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1B4B),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Live GPS Fleet Tracking System',
                                    style: TextStyle(
                                      color: Color(0xFF475569),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Modern Segmented Tab Toggle
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => setState(() => _isRegisterMode = false),
                                borderRadius: BorderRadius.circular(24),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_isRegisterMode ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: !_isRegisterMode
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.08),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: !_isRegisterMode ? const Color(0xFF4338CA) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => setState(() => _isRegisterMode = true),
                                borderRadius: BorderRadius.circular(24),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isRegisterMode ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: _isRegisterMode
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.08),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    'Register New User',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _isRegisterMode ? const Color(0xFF4338CA) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Card Container with Top Accent Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.08),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: const Color(0xFF4338CA).withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 4,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF06B6D4)],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
                              child: !_isRegisterMode ? _buildLoginForm(auth) : _buildRegisterForm(auth),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(AuthProvider auth) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Demo Switcher Header
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'QUICK DEMO LOGIN',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            ],
          ),
          const SizedBox(height: 12),

          // Two Quick Action Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ActionChip(
                elevation: 1,
                pressElevation: 2,
                avatar: const Icon(Icons.directions_bus_rounded, size: 16, color: Colors.white),
                backgroundColor: const Color(0xFF4338CA),
                label: const Text(
                  'User A (Route A / BUS-001)',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onPressed: () => _fillCredentials('user_a@example.com', 'Password123!'),
              ),
              ActionChip(
                elevation: 1,
                pressElevation: 2,
                avatar: const Icon(Icons.directions_bus_rounded, size: 16, color: Colors.white),
                backgroundColor: const Color(0xFF0D9488),
                label: const Text(
                  'User B (Route B / BUS-002)',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onPressed: () => _fillCredentials('user_b@example.com', 'Password123!'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Username or Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Username or Email',
              labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF4338CA), size: 20),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF4338CA), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF4338CA), size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF94A3B8), size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF4338CA), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            ),
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 24),

          // Gradient Submit Button
          Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF3B82F6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4338CA).withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: auth.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Sign In to Fleet Tracker', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // Switch to Register TextButton
          Center(
            child: TextButton(
              onPressed: () => setState(() => _isRegisterMode = true),
              child: const Text(
                "Don't have an account? Register New User",
                style: TextStyle(color: Color(0xFF4338CA), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(AuthProvider auth) {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_add_rounded, color: Color(0xFF0D9488), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Account',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'Assign user to an official transit corridor',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Full Name
          TextFormField(
            controller: _fullNameController,
            decoration: InputDecoration(
              labelText: 'Full Name (e.g. Suresh Kumar)',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF0D9488), size: 20),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),

          // Username
          TextFormField(
            controller: _regUsernameController,
            decoration: InputDecoration(
              labelText: 'Username *',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF0D9488), size: 20),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Username is required' : null,
          ),
          const SizedBox(height: 12),

          // Email
          TextFormField(
            controller: _regEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address *',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              prefixIcon: const Icon(Icons.mail_outline, color: Color(0xFF0D9488), size: 20),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Email is required';
              if (!val.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Password
          TextFormField(
            controller: _regPasswordController,
            obscureText: _obscureRegPassword,
            decoration: InputDecoration(
              labelText: 'Password *',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0D9488), size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscureRegPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF94A3B8), size: 20),
                onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Password is required';
              if (val.length < 6) return 'At least 6 characters required';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Route Assignment Dropdown
          Text(
            'ASSIGN TRANSIT CORRIDOR',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedAssignment,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 1,
                    child: Text('Route A: Downtown Express (BUS-001)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                  DropdownMenuItem(
                    value: 2,
                    child: Text('Route B: Campus Shuttle (BUS-002)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                  DropdownMenuItem(
                    value: 3,
                    child: Text('Route C: IT Corridor (BUS-003)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                  DropdownMenuItem(
                    value: 4,
                    child: Text('Route D: Airport Express (BUS-004)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                  DropdownMenuItem(
                    value: 5,
                    child: Text('Route E: Hosur - Chennai Superfast (BUS-005)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedAssignment = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Security Shield Info
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: Color(0xFFB45309)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Backend strictly restricts your live tracking view to this assigned vehicle (403 Isolation).',
                    style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Submit Register Button
          Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: auth.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Create Account & Sign In', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(width: 8),
                        Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.white),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),

          Center(
            child: TextButton(
              onPressed: () => setState(() => _isRegisterMode = false),
              child: const Text(
                'Already have an account? Sign In',
                style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
