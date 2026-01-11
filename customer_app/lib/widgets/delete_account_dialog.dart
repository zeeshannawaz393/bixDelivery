import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/colors.dart';

class DeleteAccountDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  final bool isLoading;

  const DeleteAccountDialog({
    super.key,
    required this.onConfirm,
    this.isLoading = false,
  });

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final TextEditingController _confirmController = TextEditingController();
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(_checkDeleteEnabled);
  }

  @override
  void dispose() {
    _confirmController.removeListener(_checkDeleteEnabled);
    _confirmController.dispose();
    super.dispose();
  }

  void _checkDeleteEnabled() {
    final canDelete = _confirmController.text.trim().toUpperCase() == 'DELETE';
    if (_canDelete != canDelete) {
      setState(() {
        _canDelete = canDelete;
      });
    }
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Icon
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: AppColors.error,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            const Text(
              'Delete Account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            // Warning Message
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: 'This action cannot be undone. All your personal data will be permanently removed and you will not be able to log in again.\n\n',
                  ),
                  TextSpan(
                    text: 'Your order history will be preserved for records, but your personal information will be anonymized.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Confirmation Input
            TextField(
              controller: _confirmController,
              enabled: !widget.isLoading,
              decoration: InputDecoration(
                labelText: 'Type "DELETE" to confirm',
                hintText: 'DELETE',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
                labelStyle: TextStyle(
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                  ),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
              onSubmitted: (_) {
                if (_canDelete && !widget.isLoading) {
                  HapticFeedback.mediumImpact();
                  widget.onConfirm();
                }
              },
            ),
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.isLoading
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Delete Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_canDelete && !widget.isLoading)
                        ? () {
                            HapticFeedback.mediumImpact();
                            widget.onConfirm();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.error.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

