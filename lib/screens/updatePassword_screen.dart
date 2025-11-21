import 'package:flutter/material.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/forgotPassword');
        return false;
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            height: screenHeight,
            child: Stack(
              children: [
                SizedBox(
                  height: screenHeight * 0.35,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/image/login.png',
                    fit: BoxFit.fitWidth,
                  ),
                ),

                Positioned(
                  top: screenHeight * 0.15,
                  left: isSmallScreen ? 20.0 : 40.0,
                  right: isSmallScreen ? 20.0 : 40.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yeni Şifre Oluştur',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 24.0 : 28.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Yeni şifre oluşturmak için şifreni gir.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 14.0 : 16.0,
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  top: screenHeight * 0.25,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 20.0 : 40.0,
                      vertical: isSmallScreen ? 20.0 : 40.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.brown[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(35),
                        topRight: Radius.circular(35),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  const SizedBox(height: 30),
                                  _buildPasswordField(
                                    label: 'Şifre',
                                    controller: passwordController,
                                    hint: 'Şifre girin',
                                    isSmallScreen: isSmallScreen,
                                    obscureText: _obscurePassword,
                                    onToggleVisibility: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  _buildPasswordField(
                                    label: 'Şifre Tekrarı',
                                    controller: confirmPasswordController,
                                    hint: 'Şifre tekrarı girin',
                                    isSmallScreen: isSmallScreen,
                                    obscureText: _obscureConfirmPassword,
                                    onToggleVisibility: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                    validator: (value) {
                                      if (value != passwordController.text) {
                                        return 'Şifreler eşleşmiyor!';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 40),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.brown[700],
                                        padding: EdgeInsets.symmetric(
                                          vertical: isSmallScreen ? 14 : 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          Navigator.pushReplacementNamed(context, '/login');
                                        }
                                      },
                                      child: Text(
                                        'Oluştur',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 16 : 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isSmallScreen,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF424242),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: onToggleVisibility,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 12 : 16,
              horizontal: 16,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
