import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/colors.dart';
import '../services/places_service.dart';

class PlacesSearchField extends StatefulWidget {
  final String? hint;
  final String? label;
  final Function(Map<String, dynamic>)? onPlaceSelected;
  final Widget? prefixIcon;

  const PlacesSearchField({
    super.key,
    this.hint,
    this.label,
    this.onPlaceSelected,
    this.prefixIcon,
  });

  @override
  State<PlacesSearchField> createState() => _PlacesSearchFieldState();
}

class _PlacesSearchFieldState extends State<PlacesSearchField> {
  final TextEditingController _controller = TextEditingController();
  final PlacesService _placesService = Get.find<PlacesService>();
  List<Map<String, dynamic>> _predictions = [];
  bool _isSearching = false;
  bool _showResults = false;
  bool _isSelectingPlace = false; // Flag to prevent search when selecting
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Don't show results if we're selecting a place
    if (_isSelectingPlace) {
      return;
    }
    
    if (_focusNode.hasFocus) {
      // Show results when focused if we have text
      if (_controller.text.isNotEmpty && _controller.text.length >= 2) {
        setState(() {
          _showResults = true;
        });
        // Trigger search if we have text but no predictions yet
        if (_predictions.isEmpty && !_isSearching) {
          _searchPlaces(_controller.text.trim());
        }
      }
    } else {
      // Delay hiding to allow tap on results, but keep showing if we have text
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_isSelectingPlace && !_focusNode.hasFocus) {
          // Only hide if user clicked outside and we're not in the middle of selecting
          setState(() {
            _showResults = false;
          });
        }
      });
    }
  }

  void _onTextChanged() {
    // Update hasText state
    final hasText = _controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    
    // Don't search if we're in the process of selecting a place
    if (_isSelectingPlace) {
      return;
    }
    
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
        _isSearching = false;
        _showResults = false;
        _hasText = false;
      });
      return;
    }

    if (query.length >= 2) {
      // Cancel previous timer
      _debounceTimer?.cancel();
      
      // Set new timer for debouncing (500ms delay)
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted && !_isSelectingPlace) {
          _searchPlaces(query);
        }
      });
    } else {
      // Clear results if query is too short
      setState(() {
        _predictions = [];
        _isSearching = false;
        _showResults = false;
      });
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (_isSelectingPlace) {
      return;
    }
    
    print('🔍 [PLACES SEARCH FIELD] Starting search for: "$query"');
    
    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    try {
      final results = await _placesService.searchPlaces(query);

      if (mounted && !_isSelectingPlace) {
        setState(() {
          _predictions = results;
          _isSearching = false;
          // Always show results if we have them, or if search completed with no results (to show "no results" message)
          _showResults = (_focusNode.hasFocus || _controller.text.isNotEmpty) && _controller.text.length >= 2;
        });
        
        if (results.isEmpty) {
          print('⚠️ [PLACES SEARCH FIELD] No results found for: "$query"');
        } else {
          print('✅ [PLACES SEARCH FIELD] Found ${results.length} results for: "$query"');
        }
      }
    } catch (e) {
      print('❌ [PLACES SEARCH FIELD] Error during search: $e');
      if (mounted) {
        setState(() {
          _predictions = [];
          _isSearching = false;
          _showResults = false;
        });
      }
    }
  }

  Future<void> _selectPlace(String placeId, String description) async {
    // Set flag to prevent search when setting text
    _isSelectingPlace = true;
    
    // Hide results immediately
    _focusNode.unfocus();
    
    // Clear predictions and hide results
    setState(() {
      _predictions = [];
      _isSearching = false;
      _showResults = false;
    });
    
    // Set the text (this won't trigger search because of the flag)
    _controller.text = description;
    
    // Reset flag after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _isSelectingPlace = false;
      }
    });
    
    // Get place details for coordinates
    final placeDetails = await _placesService.getPlaceDetails(placeId);
    if (placeDetails != null && widget.onPlaceSelected != null) {
      final location = {
        'address': description,
        'placeId': placeId,
        'lat': placeDetails['geometry']?['location']?['lat'],
        'lng': placeDetails['geometry']?['location']?['lng'],
      };
      widget.onPlaceSelected!(location);
    }
  }

  Widget _buildDropdownList(double? width) {
    // Show loading indicator when searching
    if (_isSearching && _controller.text.length >= 2) {
      return Container(
        width: width,
        margin: const EdgeInsets.only(top: 4),
        constraints: const BoxConstraints(minHeight: 60),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    // Don't show dropdown if no results and not searching
    if (!_showResults || (_predictions.isEmpty && !_isSearching)) {
      return const SizedBox.shrink();
    }

    // Show "No results" message if search completed with no results
    if (_predictions.isEmpty && !_isSearching && _controller.text.length >= 2) {
      return Container(
        width: width,
        margin: const EdgeInsets.only(top: 4),
        constraints: const BoxConstraints(minHeight: 50),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No places found. Try a different search.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: width,
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: _predictions.length,
        itemBuilder: (context, index) {
          final prediction = _predictions[index];
          final description = prediction['description'] as String? ?? '';
          final placeId = prediction['place_id'] as String? ?? '';

          if (placeId.isEmpty) {
            return const SizedBox.shrink();
          }

          return InkWell(
            onTap: () {
              _selectPlace(placeId, description);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  widget.label!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            Container(
              constraints: const BoxConstraints(
                minHeight: 56,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint ?? widget.label,
                    hintStyle: TextStyle(
                      fontSize: 17,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: widget.prefixIcon,
                    suffixIcon: _hasText
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () {
                              _controller.clear();
                              setState(() {
                                _predictions = [];
                                _showResults = false;
                                _hasText = false;
                              });
                            },
                          )
                        : Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                              size: 24,
                            ),
                          ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ),
            _buildDropdownList(constraints.maxWidth),
          ],
        );
      },
    );
  }
}

