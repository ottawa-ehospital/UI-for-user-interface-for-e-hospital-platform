import 'package:ehosptal_flutter_revamp/Service/API_service.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/Doctor_Dashboard_Screen.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/PatientPortal/screens/Patient_Dashboard_Screen.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/PharmaceuticalOffice/screens/pharma_office_shell.dart';
import 'package:ehosptal_flutter_revamp/View/Screens/Standalone_Screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // All three role types supported
  final List<String> roles = const ["Doctor", "Patient", "Pharmaceutical Office"];
  String selectedRole = "Doctor";

  bool rememberMe = false;
  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> onLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    // Pharmaceutical Office bypasses API — no backend credentials needed yet
    if (selectedRole == "Pharmaceutical Office") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PharmaOfficeShell()),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final api = ApiService();
      final res = await api.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        role: selectedRole,
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => selectedRole == "Doctor"
              ? DoctorDashboardScreen(doctor: res)
              : PatientDashboardScreen(patient: res),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF3F7FF);
    const primary = Color(0xFF1E4ED8);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 900;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 40,
                vertical: isMobile ? 18 : 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: (!kIsWeb)
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      SvgPicture.asset("assets/ehospital_logo.svg", height: 72),
                      const SizedBox(width: 12),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: isMobile
                            ? _MobileLayout(primary: primary)
                            : _DesktopLayout(
                                primary: primary,
                                formKey: _formKey,
                                roles: roles,
                                selectedRole: selectedRole,
                                onRoleChanged: (v) =>
                                    setState(() => selectedRole = v),
                                emailController: emailController,
                                passwordController: passwordController,
                                rememberMe: rememberMe,
                                onRememberChanged: (v) =>
                                    setState(() => rememberMe = v),
                                obscurePassword: obscurePassword,
                                onTogglePassword: () => setState(
                                    () => obscurePassword = !obscurePassword),
                                isLoading: isLoading,
                                onLogin: onLogin,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _MobileLayout({required Color primary}) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _LoginCard(
            primary: primary,
            formKey: _formKey,
            roles: roles,
            selectedRole: selectedRole,
            onRoleChanged: (v) => setState(() => selectedRole = v),
            emailController: emailController,
            passwordController: passwordController,
            rememberMe: rememberMe,
            onRememberChanged: (v) => setState(() => rememberMe = v),
            obscurePassword: obscurePassword,
            onTogglePassword: () =>
                setState(() => obscurePassword = !obscurePassword),
            isLoading: isLoading,
            onLogin: onLogin,
          ),
          const SizedBox(height: 18),
          Image.asset("assets/doctors_illustration.png",
              height: 320, fit: BoxFit.contain),
        ],
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.primary,
    required this.formKey,
    required this.roles,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.emailController,
    required this.passwordController,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.isLoading,
    required this.onLogin,
  });

  final Color primary;
  final GlobalKey<FormState> formKey;
  final List<String> roles;
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final bool isLoading;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _LoginCard(
              primary: primary,
              formKey: formKey,
              roles: roles,
              selectedRole: selectedRole,
              onRoleChanged: onRoleChanged,
              emailController: emailController,
              passwordController: passwordController,
              rememberMe: rememberMe,
              onRememberChanged: onRememberChanged,
              obscurePassword: obscurePassword,
              onTogglePassword: onTogglePassword,
              isLoading: isLoading,
              onLogin: onLogin,
            ),
          ),
        ),
        const SizedBox(width: 40),
        Expanded(
          flex: 6,
          child: Align(
            alignment: Alignment.centerRight,
            child: Image.asset("assets/doctors_illustration.png",
                height: 460, fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.primary,
    required this.formKey,
    required this.roles,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.emailController,
    required this.passwordController,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.isLoading,
    required this.onLogin,
  });

  final Color primary;
  final GlobalKey<FormState> formKey;
  final List<String> roles;
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final bool isLoading;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    const fieldFill = Color(0xFFF5F6F8);

    InputDecoration decoration(String hint, {Widget? suffixIcon}) {
      return InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: fieldFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixIcon,
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 30,
              offset: const Offset(0, 12),
              color: Colors.black.withOpacity(0.08),
            ),
          ],
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: decoration("Select a role"),
                items: roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) { if (v != null) onRoleChanged(v); },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: decoration("Email address"),
                validator: (v) {
                  final value = (v ?? "").trim();
                  if (value.isEmpty) return "Email is required";
                  if (!value.contains("@")) return "Enter a valid email";
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: decoration(
                  "Password",
                  suffixIcon: IconButton(
                    onPressed: onTogglePassword,
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: Colors.black54,
                    ),
                  ),
                ),
                validator: (v) {
                  if ((v ?? "").isEmpty) return "Password is required";
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: (v) => onRememberChanged(v ?? false),
                  ),
                  const Text("Remember me",
                      style: TextStyle(color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: Colors.white),
                        )
                      : const Text("Login",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ",
                      style: TextStyle(color: Colors.black54)),
                  GestureDetector(
                    onTap: () {}, // TODO: navigate to signup
                    child: Text("Sign up",
                        style: TextStyle(
                            color: primary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const StandaloneScreen()),
                ),
                child: const Text(
                  "Standalone",
                  style: TextStyle(color: Colors.black45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
