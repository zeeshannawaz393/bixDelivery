import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import 'supplies_webview_screen.dart';

class SupplierLogoItem {
  final String name;
  final String assetPath;
  final double scale;

  const SupplierLogoItem({
    required this.name,
    required this.assetPath,
    // Slight zoom to reduce built-in whitespace in some logos.
    // Keep conservative to avoid trimming.
    this.scale = 1.03,
  });
}

class OrderSuppliesScreen extends StatelessWidget {
  const OrderSuppliesScreen({super.key});

  static const List<SupplierLogoItem> _suppliers = [
    SupplierLogoItem(
      name: 'Reece',
      assetPath: 'assets/images/order_supplies/Reece_PlumbingHVAC_Supplier_Logo.webp',
      scale: 1.08,
    ),
    SupplierLogoItem(
      name: 'Pace Supply',
      assetPath: 'assets/images/order_supplies/PaceSupply_PlumbingIndustrial_Supplier_Logo.svg',
      scale: 1.04,
    ),
    SupplierLogoItem(
      name: 'Hirsch',
      assetPath: 'assets/images/order_supplies/Hirsch_PipeSupply_Supplier_Logo',
      scale: 1.02,
    ),
    SupplierLogoItem(
      name: 'Slakey',
      assetPath: 'assets/images/order_supplies/Slakey_brothers_PlumbingIndustrial_Supplier_Logo.png',
      scale: 1.04,
    ),
    SupplierLogoItem(
      name: 'AC Pro',
      assetPath: 'assets/images/order_supplies/ACPro_HVAC_Supplier_Logo.png',
      scale: 1.05,
    ),
    SupplierLogoItem(
      name: 'Ferguson',
      assetPath: 'assets/images/order_supplies/Ferguson_PlumbingHVAC_Supplier_Logo.jpg',
      scale: 1.08,
    ),
    SupplierLogoItem(
      name: 'Johnstone',
      assetPath: 'assets/images/order_supplies/Johnstone_HVAC_Supplier_Logo.svg',
      scale: 1.05,
    ),
    SupplierLogoItem(
      name: 'Hajoca',
      assetPath: 'assets/images/order_supplies/Hajoca_Plumbing_Supplier_Logo.svg',
      scale: 1.05,
    ),
    SupplierLogoItem(
      name: 'Standard',
      assetPath: 'assets/images/order_supplies/Standard_PlumbingIndustrial_Supplier_Logo.jpeg',
      // This image has lots of whitespace; zoom it a bit more.
      scale: 1.6,
    ),
    SupplierLogoItem(
      name: 'US Air',
      assetPath: 'assets/images/order_supplies/USAirConditioning_HVAC_Supplier_Logo.jpg',
      scale: 1.06,
    ),
    SupplierLogoItem(
      name: 'US Supply',
      assetPath: 'assets/images/order_supplies/USSupply_PlumbingHVAC_Supplier_Logo.webp',
      scale: 1.08,
    ),
    SupplierLogoItem(
      name: 'Apollo',
      assetPath: 'assets/images/order_supplies/Apollo_HVAC_ServiceSupply_Logo.png',
      scale: 1.00,
    ),
    SupplierLogoItem(
      name: 'Matco Norca',
      assetPath: 'assets/images/order_supplies/MatcoNorca_Valves_WasherShutoff_Logo.png',
      scale: 1.05,
    ),
  ];

  Future<void> _openSuppliesWebView() async {
    await Get.to(
      () => const SuppliesWebViewScreen(
        initialUrl: AppConstants.suppliesUrl,
        title: 'bixdelivery.com',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewPadding.bottom;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          child: Column(
            children: [
              const SizedBox(height: 6),
              const Text(
                'Order Supplies',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tap any supplier logo to shop. Then come back to create delivery.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.35,
                  color: AppColors.textSecondary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    // Slightly taller cards so logos feel larger.
                    childAspectRatio: 0.92,
                  ),
                  itemCount: _suppliers.length,
                  itemBuilder: (context, index) {
                    final item = _suppliers[index];
                    return _SupplierCard(
                      name: item.name,
                      assetPath: item.assetPath,
                      scale: item.scale,
                      onTap: _openSuppliesWebView,
                    );
                  },
                ),
              ),
              SizedBox(height: 8 + bottomInset),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text(
                    'Back to Create Delivery',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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

class _SupplierCard extends StatelessWidget {
  final String name;
  final String assetPath;
  final double scale;
  final VoidCallback onTap;

  const _SupplierCard({
    required this.name,
    required this.assetPath,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Ferguson SVG was white; we used a dark background.
    // Now the updated Ferguson asset is a JPG, so no special background needed.
    const needsDarkLogoBackground = false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                // Reduce padding so the logo area is bigger.
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Container(
                          // Smaller inner padding = bigger logo.
                          padding: const EdgeInsets.all(0),
                          decoration: BoxDecoration(
                            color: needsDarkLogoBackground ? const Color(0xFF12113F) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SizedBox.expand(
                            // Hard clip inside rounded container so zoomed logos never overflow the card.
                            child: Transform.scale(
                              scale: scale,
                              child: Center(child: _AssetLoader(assetPath: assetPath)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget that attempts to locate an asset (with or without extension) and render it.
class _AssetLoader extends StatefulWidget {
  final String assetPath;
  const _AssetLoader({required this.assetPath});

  @override
  State<_AssetLoader> createState() => _AssetLoaderState();
}

class _AssetLoaderState extends State<_AssetLoader> {
  String? _resolvedPath;
  bool _isSvg = false;

  static const _tryExtensions = ['.svg', '.png', '.webp', '.jpg', '.jpeg'];

  @override
  void initState() {
    super.initState();
    _resolveAsset();
  }

  Future<void> _resolveAsset() async {
    final base = widget.assetPath;
    final candidates = <String>[];
    candidates.add(base);
    // if base has no extension, try common ones
    if (!base.contains('.')) {
      for (final ext in _tryExtensions) {
        candidates.add(base + ext);
      }
    } else {
      // also try replacing extension with common ones (in case of mismatches)
      final dotIndex = base.lastIndexOf('.');
      final root = base.substring(0, dotIndex);
      for (final ext in _tryExtensions) {
        candidates.add(root + ext);
      }
    }

    for (final c in candidates) {
      try {
        // Try to load via rootBundle; this checks packaged assets
        await rootBundle.load(c);
        // Found it
        if (!mounted) return;
        setState(() {
          _resolvedPath = c;
          _isSvg = c.toLowerCase().endsWith('.svg');
        });
        return;
      } catch (_) {
        // ignore and try next
      }
    }

    // If none found, set to null to show placeholder
    if (mounted) {
      setState(() {
        _resolvedPath = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resolvedPath == null) {
      // Loading state or not found; show placeholder
      return const Icon(Icons.storefront_outlined, size: 36, color: Colors.grey);
    }

    if (_isSvg) {
      try {
        return SvgPicture.asset(_resolvedPath!, fit: BoxFit.contain);
      } catch (_) {
        return const Icon(Icons.broken_image, size: 36, color: Colors.grey);
      }
    } else {
      return Image.asset(
        _resolvedPath!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 36, color: Colors.grey),
      );
    }
  }
}

