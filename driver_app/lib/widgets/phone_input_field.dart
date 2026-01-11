import 'package:flutter/material.dart';
import '../utils/colors.dart';

class Country {
  final String name;
  final String code;
  final String dialCode;

  const Country({
    required this.name,
    required this.code,
    required this.dialCode,
  });
}

class PhoneInputField extends StatefulWidget {
  final String? label;
  final TextEditingController? countryCodeController;
  final TextEditingController? phoneController;
  final String? Function(String?)? validator;

  const PhoneInputField({
    super.key,
    this.label,
    this.countryCodeController,
    this.phoneController,
    this.validator,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  String? _errorText;
  final GlobalKey<FormFieldState> _phoneFieldKey = GlobalKey<FormFieldState>();
  Country _selectedCountry = const Country(name: 'United States', code: 'US', dialCode: '+1');
  TextEditingController? _countryCodeController;
  TextEditingController? _phoneController;

  final List<Country> _countries = const [
    Country(name: 'United States', code: 'US', dialCode: '+1'),
    Country(name: 'United Kingdom', code: 'GB', dialCode: '+44'),
    Country(name: 'India', code: 'IN', dialCode: '+91'),
    Country(name: 'China', code: 'CN', dialCode: '+86'),
    Country(name: 'France', code: 'FR', dialCode: '+33'),
    Country(name: 'Germany', code: 'DE', dialCode: '+49'),
    Country(name: 'Japan', code: 'JP', dialCode: '+81'),
    Country(name: 'Australia', code: 'AU', dialCode: '+61'),
    Country(name: 'United Arab Emirates', code: 'AE', dialCode: '+971'),
    Country(name: 'Saudi Arabia', code: 'SA', dialCode: '+966'),
    Country(name: 'Pakistan', code: 'PK', dialCode: '+92'),
    Country(name: 'South Africa', code: 'ZA', dialCode: '+27'),
    Country(name: 'Canada', code: 'CA', dialCode: '+1'),
    Country(name: 'Brazil', code: 'BR', dialCode: '+55'),
    Country(name: 'Mexico', code: 'MX', dialCode: '+52'),
    Country(name: 'Spain', code: 'ES', dialCode: '+34'),
    Country(name: 'Italy', code: 'IT', dialCode: '+39'),
    Country(name: 'Russia', code: 'RU', dialCode: '+7'),
    Country(name: 'South Korea', code: 'KR', dialCode: '+82'),
    Country(name: 'Turkey', code: 'TR', dialCode: '+90'),
    Country(name: 'Indonesia', code: 'ID', dialCode: '+62'),
    Country(name: 'Netherlands', code: 'NL', dialCode: '+31'),
    Country(name: 'Belgium', code: 'BE', dialCode: '+32'),
    Country(name: 'Switzerland', code: 'CH', dialCode: '+41'),
    Country(name: 'Sweden', code: 'SE', dialCode: '+46'),
    Country(name: 'Norway', code: 'NO', dialCode: '+47'),
    Country(name: 'Denmark', code: 'DK', dialCode: '+45'),
    Country(name: 'Poland', code: 'PL', dialCode: '+48'),
    Country(name: 'Argentina', code: 'AR', dialCode: '+54'),
    Country(name: 'Chile', code: 'CL', dialCode: '+56'),
    Country(name: 'Colombia', code: 'CO', dialCode: '+57'),
    Country(name: 'Peru', code: 'PE', dialCode: '+51'),
    Country(name: 'Venezuela', code: 'VE', dialCode: '+58'),
    Country(name: 'Egypt', code: 'EG', dialCode: '+20'),
    Country(name: 'Nigeria', code: 'NG', dialCode: '+234'),
    Country(name: 'Kenya', code: 'KE', dialCode: '+254'),
    Country(name: 'Ghana', code: 'GH', dialCode: '+233'),
    Country(name: 'Morocco', code: 'MA', dialCode: '+212'),
    Country(name: 'Algeria', code: 'DZ', dialCode: '+213'),
    Country(name: 'Tunisia', code: 'TN', dialCode: '+216'),
    Country(name: 'Bangladesh', code: 'BD', dialCode: '+880'),
    Country(name: 'Philippines', code: 'PH', dialCode: '+63'),
    Country(name: 'Vietnam', code: 'VN', dialCode: '+84'),
    Country(name: 'Thailand', code: 'TH', dialCode: '+66'),
    Country(name: 'Malaysia', code: 'MY', dialCode: '+60'),
    Country(name: 'Singapore', code: 'SG', dialCode: '+65'),
    Country(name: 'New Zealand', code: 'NZ', dialCode: '+64'),
    Country(name: 'Israel', code: 'IL', dialCode: '+972'),
    Country(name: 'Lebanon', code: 'LB', dialCode: '+961'),
    Country(name: 'Jordan', code: 'JO', dialCode: '+962'),
    Country(name: 'Kuwait', code: 'KW', dialCode: '+965'),
    Country(name: 'Qatar', code: 'QA', dialCode: '+974'),
    Country(name: 'Oman', code: 'OM', dialCode: '+968'),
    Country(name: 'Bahrain', code: 'BH', dialCode: '+973'),
    Country(name: 'Iraq', code: 'IQ', dialCode: '+964'),
    Country(name: 'Iran', code: 'IR', dialCode: '+98'),
    Country(name: 'Afghanistan', code: 'AF', dialCode: '+93'),
    Country(name: 'Sri Lanka', code: 'LK', dialCode: '+94'),
    Country(name: 'Nepal', code: 'NP', dialCode: '+977'),
    Country(name: 'Myanmar', code: 'MM', dialCode: '+95'),
    Country(name: 'Cambodia', code: 'KH', dialCode: '+855'),
    Country(name: 'Laos', code: 'LA', dialCode: '+856'),
    Country(name: 'Mongolia', code: 'MN', dialCode: '+976'),
    Country(name: 'Kazakhstan', code: 'KZ', dialCode: '+7'),
    Country(name: 'Uzbekistan', code: 'UZ', dialCode: '+998'),
    Country(name: 'Ukraine', code: 'UA', dialCode: '+380'),
    Country(name: 'Romania', code: 'RO', dialCode: '+40'),
    Country(name: 'Czech Republic', code: 'CZ', dialCode: '+420'),
    Country(name: 'Hungary', code: 'HU', dialCode: '+36'),
    Country(name: 'Greece', code: 'GR', dialCode: '+30'),
    Country(name: 'Portugal', code: 'PT', dialCode: '+351'),
    Country(name: 'Ireland', code: 'IE', dialCode: '+353'),
    Country(name: 'Finland', code: 'FI', dialCode: '+358'),
    Country(name: 'Austria', code: 'AT', dialCode: '+43'),
  ];

  @override
  void initState() {
    super.initState();

    // Use provided controllers or create new ones
    _countryCodeController = widget.countryCodeController ?? TextEditingController();
    _phoneController = widget.phoneController ?? TextEditingController();

    // Initialize country code
    if (_countryCodeController!.text.isNotEmpty) {
      final dialCode = _countryCodeController!.text;
      final country = _countries.firstWhere(
        (c) => c.dialCode == dialCode,
        orElse: () => _selectedCountry,
      );
      _selectedCountry = country;
    } else {
      _countryCodeController?.text = _selectedCountry.dialCode;
    }
  }

  String _getFlagEmoji(String countryCode) {
    final codePoints = countryCode
        .toUpperCase()
        .split('')
        .map((char) => 127397 + char.codeUnitAt(0))
        .toList();
    return String.fromCharCodes(codePoints);
  }

  Widget _buildCountryCodeField() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(
          color: _errorText != null
              ? AppColors.error.withValues(alpha: 0.5)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showCountryPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getFlagEmoji(_selectedCountry.code),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _selectedCountry.dialCode,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    final favoriteCountries = [
      'US', 'GB', 'IN', 'CN', 'FR', 'DE', 'JP', 'AU', 'AE', 'SA', 'PK', 'ZA',
    ];
    
    final favoriteList = _countries.where((c) => favoriteCountries.contains(c.code)).toList();
    final otherList = _countries.where((c) => !favoriteCountries.contains(c.code)).toList();
    final allCountries = [...favoriteList, ...otherList];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Country',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: allCountries.length,
                itemBuilder: (context, index) {
                  final country = allCountries[index];
                  final isSelected = country.code == _selectedCountry.code;
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCountry = country;
                        _countryCodeController?.text = country.dialCode;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Text(
                            _getFlagEmoji(country.code),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  country.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  country.dialCode,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              color: AppColors.primaryBlue,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneTextField() {
    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(
          color: _errorText != null
              ? AppColors.error.withValues(alpha: 0.5)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: TextFormField(
          key: _phoneFieldKey,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          validator: (value) {
            if (widget.validator != null) {
              final fullNumber = '${_countryCodeController?.text}${_phoneController?.text}';
              final error = widget.validator!(fullNumber.isEmpty ? null : fullNumber);
              setState(() {
                _errorText = error;
              });
              return error;
            }
            return null;
          },
          onChanged: (value) {
            if (_errorText != null) {
              _phoneFieldKey.currentState?.validate();
            }
          },
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
            decoration: TextDecoration.none,
            decorationThickness: 0,
          ),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.phone_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            hintText: widget.label ?? 'Phone Number',
            hintStyle: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              fontWeight: FontWeight.w400,
              letterSpacing: -0.3,
              decoration: TextDecoration.none,
              decorationThickness: 0,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorStyle: const TextStyle(height: 0, fontSize: 0),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 0,
            ),
            isDense: true,
            counterText: '',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildCountryCodeField(),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: _buildPhoneTextField(),
            ),
          ],
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 14,
                  color: AppColors.error,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _errorText!,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.error,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.2,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    // Dispose controllers if we created them
    if (widget.countryCodeController == null) {
      _countryCodeController?.dispose();
    }
    if (widget.phoneController == null) {
      _phoneController?.dispose();
    }
    super.dispose();
  }
}

