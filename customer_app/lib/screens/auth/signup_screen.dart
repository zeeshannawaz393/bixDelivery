import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/colors.dart';
import '../../widgets/glass_input_field.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/phone_input_field.dart';
import '../../widgets/custom_toast.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _countryCodeController = TextEditingController(text: '+1');
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _countryCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      // Phone number is optional - only include if provided
      final phoneNumber = _phoneController.text.trim().isEmpty 
          ? null 
          : '${_countryCodeController.text}${_phoneController.text}';
      final email = _emailController.text.trim();
      final fullName = _fullNameController.text.trim();
      
      print('📝 [SIGN UP] Form Data:');
      print('   Email: $email');
      print('   Full Name: $fullName');
      print('   Phone Number: ${phoneNumber ?? "Not provided"}');
      print('   Password: ${'*' * _passwordController.text.length} (${_passwordController.text.length} chars)');
      
      final success = await _authController.signUp(
        email: email,
        password: _passwordController.text,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );

      if (success) {
        CustomToast.success(context, 'Account created successfully!');
        Get.offAllNamed('/home');
      } else {
        CustomToast.error(
          context,
          _authController.errorMessage.value.isNotEmpty
              ? _authController.errorMessage.value
              : 'Failed to sign up. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside
            FocusScope.of(context).unfocus();
          },
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // App Logo
                      Center(
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Title - Get Started
                      const Center(
                        child: Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Subtitle
                      Center(
                        child: Text(
                          'Sign up to start ordering',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Input Fields
                      GlassInputField(
                        label: 'Company Name',
                        controller: _fullNameController,
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: AppColors.textSecondary,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your company name';
                          }
                          final trimmedValue = value.trim();
                          if (trimmedValue.isEmpty) {
                            return 'Company name cannot be empty';
                          }
                          if (trimmedValue.length < 2) {
                            return 'Company name must be at least 2 characters';
                          }
                          if (trimmedValue.length > 50) {
                            return 'Company name must be less than 50 characters';
                          }
                          // Check if name contains only letters, spaces, and common name characters
                          final nameRegex = RegExp(r"^[a-zA-Z\s'-]+$");
                          if (!nameRegex.hasMatch(trimmedValue)) {
                            return 'Company name can only contain letters, spaces, hyphens, and apostrophes';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      PhoneInputField(
                        label: 'Phone Number (Optional)',
                        countryCodeController: _countryCodeController,
                        phoneController: _phoneController,
                        validator: (value) {
                          // Phone number is optional, but if provided, validate it
                          final phoneNumber = _phoneController.text;
                          if (phoneNumber.isEmpty) {
                            // Empty is valid (optional field)
                            return null;
                          }
                          // Remove any non-digit characters for validation (only from phone number, not country code)
                          final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
                          if (digitsOnly.isEmpty) {
                            return 'Please enter a valid phone number';
                          }
                          if (digitsOnly.length < 10) {
                            return 'Phone number must be at least 10 digits';
                          }
                          if (digitsOnly.length > 10) {
                            return 'Phone number must be exactly 10 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      GlassInputField(
                        label: 'Email Address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: AppColors.textSecondary,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email address';
                          }
                          final trimmedValue = value.trim();
                          if (trimmedValue.isEmpty) {
                            return 'Email address cannot be empty';
                          }
                          if (!GetUtils.isEmail(trimmedValue)) {
                            return 'Please enter a valid email address';
                          }
                          // Additional email validation
                          if (trimmedValue.length > 100) {
                            return 'Email address is too long';
                          }
                          // Check for common email format issues
                          if (trimmedValue.startsWith('.') || trimmedValue.endsWith('.')) {
                            return 'Email address cannot start or end with a dot';
                          }
                          if (trimmedValue.contains('..')) {
                            return 'Email address cannot contain consecutive dots';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      GlassInputField(
                        label: 'Create Password',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          if (value.length > 128) {
                            return 'Password must be less than 128 characters';
                          }
                          // Check for at least one letter and one number (recommended but not required)
                          final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
                          final hasNumber = RegExp(r'[0-9]').hasMatch(value);
                          if (!hasLetter) {
                            return 'Password must contain at least one letter';
                          }
                          if (!hasNumber) {
                            return 'Password must contain at least one number';
                          }
                          // Check for common weak passwords
                          final commonPasswords = ['password', '123456', '12345678', 'qwerty', 'abc123'];
                          if (commonPasswords.contains(value.toLowerCase())) {
                            return 'Please choose a stronger password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      // Sign Up Button
                      Obx(() => GlassButton(
                        text: 'Sign Up',
                        onPressed: () {
                          print('🔘 [SIGN UP SCREEN] Sign Up button clicked');
                          print('   Email: ${_emailController.text.trim()}');
                          print('   Full Name: ${_fullNameController.text.trim()}');
                          _handleSignUp();
                        },
                        isLoading: _authController.isLoading.value,
                      )),
                      const SizedBox(height: 24),
                      // Login Link
                      Center(
                        child: TextButton(
                          onPressed: () => Get.toNamed('/login'),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                const TextSpan(text: 'Already have an account? '),
                                TextSpan(
                                  text: 'Login',
                                  style: const TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom Navigation Bar - Commented out
            // Container(
            //   decoration: BoxDecoration(
            //     color: Colors.white,
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.black.withValues(alpha: 0.05),
            //         blurRadius: 10,
            //         offset: const Offset(0, -2),
            //       ),
            //     ],
            //   ),
            //   child: SafeArea(
            //     child: Container(
            //       height: 60,
            //       padding: const EdgeInsets.symmetric(horizontal: 20),
            //       child: Row(
            //         mainAxisAlignment: MainAxisAlignment.spaceAround,
            //         children: [
            //           // Requests Tab (Selected)
            //           Expanded(
            //             child: InkWell(
            //               onTap: () {
            //                 // Already on signup, which is part of requests flow
            //               },
            //               child: Column(
            //                 mainAxisAlignment: MainAxisAlignment.center,
            //                 children: [
            //                   Icon(
            //                     Icons.description,
            //                     color: AppColors.primaryBlue,
            //                     size: 24,
            //                   ),
            //                   const SizedBox(height: 4),
            //                   Text(
            //                     'Requests',
            //                     style: TextStyle(
            //                       fontSize: 12,
            //                       color: AppColors.primaryBlue,
            //                       fontWeight: FontWeight.w600,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //           // Login Tab
            //           Expanded(
            //             child: InkWell(
            //               onTap: () => Get.toNamed('/login'),
            //               child: Column(
            //                 mainAxisAlignment: MainAxisAlignment.center,
            //                 children: [
            //                   Icon(
            //                     Icons.person_outline,
            //                     color: AppColors.textSecondary,
            //                     size: 24,
            //                   ),
            //                   const SizedBox(height: 4),
            //                   Text(
            //                     'Login',
            //                     style: TextStyle(
            //                       fontSize: 12,
            //                       color: AppColors.textSecondary,
            //                       fontWeight: FontWeight.w400,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
        ),
      ),
    );
  }
}
