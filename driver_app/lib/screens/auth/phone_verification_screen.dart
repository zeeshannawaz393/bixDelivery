import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_toast.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    AppConstants.otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    AppConstants.otpLength,
    (_) => FocusNode(),
  );
  final AuthController _authController = Get.find<AuthController>();
  String? _verificationId;
  String? _phoneNumber;
  int _resendTimer = 0;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    _verificationId = args?['verificationId'];
    _phoneNumber = args?['phoneNumber'];
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = AppConstants.otpResendTimer;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendTimer--;
        });
        return _resendTimer > 0;
      }
      return false;
    });
  }

  void _onOTPChanged(int index, String value) {
    if (value.length == 1 && index < AppConstants.otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != AppConstants.otpLength) {
      CustomToast.error(context, 'Please enter complete OTP');
      return;
    }

    if (_verificationId != null) {
      final success = await _authController.verifyOTP(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      if (success && mounted) {
        Get.offAllNamed('/home');
      }
    }
  }

  Future<void> _resendOTP() async {
    if (_phoneNumber != null && _resendTimer == 0) {
      final verificationId = await _authController.sendOTP(_phoneNumber!);
      if (verificationId != null) {
        setState(() {
          _verificationId = verificationId;
        });
      }
      _startResendTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone Number'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Enter Verification Code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a code to ${_phoneNumber ?? "your phone"}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    AppConstants.otpLength,
                    (index) => SizedBox(
                      width: 50,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) => _onOTPChanged(index, value),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Obx(() => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _authController.isLoading.value
                      ? null
                      : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _authController.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              )),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _resendTimer > 0 ? null : _resendOTP,
                  child: Text(
                    _resendTimer > 0
                        ? 'Resend code in $_resendTimer seconds'
                        : 'Resend Code',
                    style: const TextStyle(color: AppColors.primaryBlue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




