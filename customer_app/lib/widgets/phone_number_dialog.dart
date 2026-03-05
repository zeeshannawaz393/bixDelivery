import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/colors.dart';
import '../widgets/phone_input_field.dart';
import '../widgets/glass_button.dart';
import '../widgets/custom_toast.dart';

class PhoneNumberDialog extends StatefulWidget {
  final String? currentPhoneNumber;
  final String? currentCountryCode;

  const PhoneNumberDialog({
    super.key,
    this.currentPhoneNumber,
    this.currentCountryCode,
  });

  @override
  State<PhoneNumberDialog> createState() => _PhoneNumberDialogState();
}

class _PhoneNumberDialogState extends State<PhoneNumberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _countryCodeController = TextEditingController(text: '+1');
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill if phone number exists
    if (widget.currentCountryCode != null) {
      _countryCodeController.text = widget.currentCountryCode!;
    }
    if (widget.currentPhoneNumber != null && widget.currentPhoneNumber != 'Not set') {
      _phoneController.text = widget.currentPhoneNumber!;
    }
  }

  @override
  void dispose() {
    _countryCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _getPhoneNumber() {
    if (_phoneController.text.trim().isEmpty) {
      return null;
    }
    return '${_countryCodeController.text}${_phoneController.text}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Phone Number Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              // Message
              Text(
                'Phone number is required so the driver can contact you during delivery.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 24),
              // Phone Input Field
              PhoneInputField(
                label: 'Phone Number',
                countryCodeController: _countryCodeController,
                phoneController: _phoneController,
                validator: (value) {
                  final phoneNumber = _phoneController.text;
                  if (phoneNumber.isEmpty) {
                    return 'Please enter your phone number';
                  }
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
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GlassButton(
                      text: 'Save & Continue',
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final phoneNumber = _getPhoneNumber();
                          if (phoneNumber != null) {
                            Navigator.of(context).pop(phoneNumber);
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
