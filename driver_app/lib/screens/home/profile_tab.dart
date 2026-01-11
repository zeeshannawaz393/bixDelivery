import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/order_controller.dart';
import '../../utils/colors.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/custom_toast.dart';
import '../../utils/constants.dart';
import '../../services/driver_service.dart';
import '../../widgets/delete_account_dialog.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final AuthController _authController;
  late final OrderController _orderController;
  late final DriverService _driverService;
  int _totalDeliveries = 0;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _orderController = Get.find<OrderController>();
    _driverService = Get.find<DriverService>();
    
    // Load profile and total deliveries when tab opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_authController.user.value != null) {
        print('🔄 [PROFILE TAB] Refreshing driver profile...');
        _authController.refreshDriverProfile();
        _loadTotalDeliveries();
      }
    });
  }

  Future<void> _loadTotalDeliveries() async {
    if (_authController.user.value != null) {
      try {
        final driverId = _authController.user.value!.uid;
        final total = await _driverService.getTotalDeliveries(driverId);
        setState(() {
          _totalDeliveries = total;
        });
      } catch (e) {
        print('❌ [PROFILE TAB] Error loading total deliveries: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
              const SizedBox(height: 16),
              // Title
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              // Profile Image - Full Width


              // Total Deliveries Card - Driver specific (clickable)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Get.toNamed('/completed-deliveries'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlueLight.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_shipping,
                            color: AppColors.primaryBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Deliveries',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_totalDeliveries',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // User Data Fields (Read-only display)
              Obx(() {
                // Access both reactive values to ensure Obx watches them
                final user = _authController.user.value;
                final profile = _authController.driverProfile.value;
                
                // Debug print
                if (profile != null) {
                  print('📱 [PROFILE TAB] Profile data: $profile');
                  print('   Phone Number from Firestore: ${profile['phoneNumber']}');
                } else {
                  print('⚠️ [PROFILE TAB] Profile is null');
                }
                
                final userData = _getUserData(user, profile);

                return Column(
                  children: [
                    // Full Name
                    _buildInfoField(
                      label: 'Full Name',
                      value: userData['fullName'] ?? 'Not set',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 8),
                    // Phone Number
                    _buildPhoneInfoField(
                      label: 'Phone Number',
                      countryCode: userData['countryCode'] ?? '+1',
                      phoneNumber: userData['phoneNumber'] ?? 'Not set',
                    ),
                    const SizedBox(height: 8),
                    // Email Address
                    _buildInfoField(
                      label: 'Email Address',
                      value: userData['email'] ?? 'Not set',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 28),
                    // Logout Button (if logged in)
                    if (user != null)
                      Obx(() {
                        // Explicitly access isLoading to ensure Obx tracks it
                        // This forces Obx to rebuild when isLoading changes
                        final isLoading = _authController.isLoading.value;
                        print('🔄 [PROFILE TAB] Logout button rebuild - isLoading: $isLoading');
                        
                        return GlassButton(
                          text: 'Logout',
                          onPressed: isLoading ? null : () async {
                            print('🔘 [PROFILE TAB] Logout button clicked');
                            print('   User: ${user?.email ?? 'Unknown'}');
                            print('   Setting isLoading to true...');
                            
                            try {
                              // Set loading state immediately - this will trigger Obx rebuild
                              _authController.isLoading.value = true;
                              print('   isLoading set to: ${_authController.isLoading.value}');
                              
                              // Force a frame to ensure UI updates
                              await Future.delayed(const Duration(milliseconds: 100));
                              
                              // Clear all session data
                              print('⏳ [PROFILE TAB] Starting logout process...');
                              await _authController.signOut();
                              
                              // Ensure loader is visible for at least 600ms total
                              await Future.delayed(const Duration(milliseconds: 500));
                              
                              // Clear order data
                              _orderController.activeOrders.clear();
                              _orderController.pendingOrders.clear();
                              
                              print('✅ [PROFILE TAB] Logout completed successfully');
                              CustomToast.success(context, 'Logged out successfully');
                              
                              // Reset loading state before navigation
                              _authController.isLoading.value = false;
                              Get.offAllNamed('/login');
                            } catch (e) {
                              _authController.isLoading.value = false;
                              print('❌ [PROFILE TAB] Error during logout: $e');
                              CustomToast.error(context, 'Failed to logout. Please try again.');
                            }
                          },
                          isLoading: isLoading,
                          icon: Icons.logout,
                        );
                      }),
                    const SizedBox(height: 28),
                    // Delete Account Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Delete Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Permanently delete your account and all associated personal data. This action cannot be undone.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _showDeleteAccountDialog(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: const BorderSide(
                                  color: AppColors.error,
                                  width: 1.5,
                                ),
                              ),
                              child: const Text(
                                'Delete Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Login/Sign Up Link (if not logged in)
                    if (user == null)
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
                                const TextSpan(text: 'Not logged in? '),
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
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, String> _getUserData(user, profile) {
    if (user == null) {
      return {};
    }

    // Parse phone number from Firestore
    String phoneNumber = 'Not set';
    String countryCode = '+1';
    
    if (profile != null && profile['phoneNumber'] != null) {
      final fullPhone = profile['phoneNumber'].toString().trim();
      
      if (fullPhone.isNotEmpty && fullPhone != 'Not set') {
        // Phone number format: +11234567890
        if (fullPhone.startsWith('+')) {
          // Extract country code
          // US/Canada: +1XXXXXXXXXX (12 chars total, +1 + 10 digits)
          if (fullPhone.startsWith('+1') && fullPhone.length >= 12) {
            countryCode = '+1';
            phoneNumber = fullPhone.substring(2); // Remove +1, keep 10 digits
          } else if (fullPhone.length > 2) {
            // Other countries - extract first 2-3 chars as country code
            // Try to detect: +XX (2 digits) or +XXX (3 digits)
            if (fullPhone.length >= 4) {
              // Try 2-digit country code first (most common)
              final potentialCode = fullPhone.substring(0, 3); // +XX
              final remaining = fullPhone.substring(3);
              
              // If remaining is reasonable length (7-15 digits), use 2-digit code
              if (remaining.length >= 7 && remaining.length <= 15) {
                countryCode = potentialCode;
                phoneNumber = remaining;
              } else if (fullPhone.length >= 5) {
                // Try 3-digit country code
                countryCode = fullPhone.substring(0, 4); // +XXX
                phoneNumber = fullPhone.substring(4);
              } else {
                // Fallback: show as is
                countryCode = '+1';
                phoneNumber = fullPhone.substring(1);
              }
            } else {
              // Too short, show as is
              phoneNumber = fullPhone;
            }
          } else {
            phoneNumber = fullPhone;
          }
        } else {
          // No + prefix, assume it's just the number
          phoneNumber = fullPhone;
        }
      }
    }

    return {
      'email': profile?['email'] ?? user.email ?? 'Not set',
      'userId': user.uid,
      'fullName': profile?['fullName'] ?? user.displayName ?? 'Not set',
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
    };
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryBlueLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryBlue,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInfoField({
    required String label,
    required String countryCode,
    required String phoneNumber,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryBlueLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.phone_outlined,
              color: AppColors.primaryBlue,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phoneNumber == 'Not set' 
                    ? '$countryCode $phoneNumber'
                    : '$countryCode $phoneNumber',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) async {
    // First check if account can be deleted
    final checkResult = await _authController.checkCanDeleteAccount();
    
    if (!checkResult['canDelete']) {
      // Show error if cannot delete
      CustomToast.error(context, checkResult['reason'] ?? 'Cannot delete account at this time.');
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DeleteAccountDialog(
        isLoading: _authController.isLoading.value,
        onConfirm: () async {
          // Close dialog first
          Navigator.of(dialogContext).pop();
          
          // Perform deletion
          final result = await _authController.deleteAccount();
          
          if (result['success'] == true) {
            // Show success message
            CustomToast.success(context, 'Your account has been deleted successfully.');
            
            // Wait a moment then redirect to login
            await Future.delayed(const Duration(milliseconds: 1500));
            Get.offAllNamed('/login');
          } else {
            // Show error message
            final error = result['error'] ?? 'Failed to delete account';
            if (result['partial'] == true) {
              CustomToast.error(context, '$error Please contact support.');
            } else {
              CustomToast.error(context, error);
            }
          }
        },
      ),
    );
  }
}
