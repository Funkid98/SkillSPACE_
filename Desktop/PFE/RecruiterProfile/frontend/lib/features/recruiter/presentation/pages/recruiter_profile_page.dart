import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:country_picker/country_picker.dart';
import 'package:country_flags/country_flags.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:reactive_theme/reactive_theme.dart';
import '../cubits/recruiter_profile_cubit.dart';
import '../../data/models/company_profile_model.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/animated_reveal.dart';
import '../../../../core/l10n/app_localizations.dart';

class RecruiterProfilePage extends StatefulWidget {
  const RecruiterProfilePage({super.key});

  @override
  State<RecruiterProfilePage> createState() => _RecruiterProfilePageState();
}

class _RecruiterProfilePageState extends State<RecruiterProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _entrepriseController;
  late TextEditingController _websiteController;
  late TextEditingController _cityController;

  // Selected values
  String? _selectedSize;
  String? _selectedYear;
  String? _selectedSector;
  String? _selectedCountry;
  String? _selectedCountryCode;

  // Logo upload
  Uint8List? _logoBytes;
  String? _logoName;
  bool _isUploading = false;

  final List<String> _sizes = [
    '0-10',
    '10',
    '50',
    '100',
    '150',
    '200',
    '500',
    '1000',
    '5000',
    '10k+'
  ];
  final List<String> _sectors = [
    'Tech',
    'Finance',
    'Santé',
    'E-commerce',
    'SaaS',
    'Education',
    'Autre'
  ];
  late List<String> _years;

  @override
  void initState() {
    super.initState();
    _entrepriseController = TextEditingController();
    _websiteController = TextEditingController();
    _cityController = TextEditingController();

    int currentYear = DateTime.now().year;
    _years = List.generate(
            currentYear - 2000 + 1, (index) => (2000 + index).toString())
        .reversed
        .toList();

    // Initial fetch if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<RecruiterProfileCubit>().state;
      if (state is RecruiterProfileLoaded) {
        _initControllers(state.profile);
      }
    });
  }

  @override
  void dispose() {
    _entrepriseController.dispose();
    _websiteController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _initControllers(CompanyProfile profile) {
    _entrepriseController.text = profile.entreprise;
    _websiteController.text = profile.siteWeb;

    if (_sizes.contains(profile.taille)) {
      _selectedSize = profile.taille;
    }
    if (_years.contains(profile.anneeCreation.toString())) {
      _selectedYear = profile.anneeCreation.toString();
    }
    if (_sectors.contains(profile.secteur)) {
      _selectedSector = profile.secteur;
    }

    // Parse location (format: "Country, City")
    if (profile.localisation.isNotEmpty) {
      final parts = profile.localisation.split(', ');
      if (parts.isNotEmpty) {
        _selectedCountry = parts[0];
        _selectedCountryCode = null;
        if (_selectedCountry != null) {
          try {
            final country = CountryService().getAll().firstWhere((c) =>
                c.name == _selectedCountry ||
                c.displayName == _selectedCountry);
            _selectedCountryCode = country.countryCode;
          } catch (_) {
            _selectedCountryCode = null;
          }
        }
        if (parts.length > 1) {
          _cityController.text = parts[1];
        }
      }
    }
    setState(() {});
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _logoBytes = result.files.single.bytes;
        _logoName = result.files.single.name;
      });
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);
      try {
        String? finalLogoUrl;
        if (_logoBytes != null && _logoName != null) {
          finalLogoUrl = await context
              .read<RecruiterProfileCubit>()
              .uploadLogo(_logoBytes!, _logoName!);
        }

        final locationString = [
          if (_selectedCountry != null) _selectedCountry,
          _cityController.text.trim(),
        ].where((s) => s != null && s.isNotEmpty).join(', ');

        final cubit = context.read<RecruiterProfileCubit>();
        final logoUrl = finalLogoUrl ??
            (cubit.state as RecruiterProfileLoaded).profile.logoUrl;

        final profile = CompanyProfile(
          entreprise: _entrepriseController.text,
          siteWeb: _websiteController.text,
          taille: _selectedSize ?? '',
          anneeCreation: int.tryParse(_selectedYear ?? '') ?? 0,
          secteur: _selectedSector ?? '',
          localisation: locationString,
          logoUrl: logoUrl,
        );

        cubit.updateProfile(profile);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Erreur: $e'), backgroundColor: Colors.red));
        }
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecruiterProfileCubit, RecruiterProfileState>(
      listener: (context, state) {
        if (state is RecruiterProfileLoaded) {
          _initControllers(state.profile);
        }
      },
      builder: (context, state) {
        if (state is RecruiterProfileLoading ||
            state is RecruiterProfileInitial ||
            _isUploading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.orange));
        }
        if (state is RecruiterProfileError) {
          return Center(child: Text(state.message));
        }
        final profile = (state as RecruiterProfileLoaded).profile;
        return _buildContent(profile, l10n: RecruiterLocalizations.of(context));
      },
    );
  }

  Widget _buildContent(CompanyProfile profile,
      {required RecruiterLocalizations l10n}) {
    final isDark = ReactiveMode.isDarkMode(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          Responsive.hPad(context), 24, Responsive.hPad(context), 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            AnimatedReveal(
              delay: const Duration(milliseconds: 100),
              direction: RevealDirection.fromTop,
              child: Text(
                l10n.companyProfileTitle,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.textDark),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedReveal(
              delay: const Duration(milliseconds: 200),
              direction: RevealDirection.fromTop,
              child: Text(
                l10n.companyProfileSubtitle,
                style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white60 : AppColors.textGray),
              ),
            ),
            const SizedBox(height: 32),

            // Main Info Card
            _buildSectionCard(
              title: l10n.companyInfo,
              icon: Icons.business_rounded,
              child: Column(
                children: [
                  _buildField(
                      label: "Nom de l'entreprise",
                      controller: _entrepriseController,
                      icon: Icons.store),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                          child: _buildDropdown(
                              label: l10n.companySize,
                              value: _selectedSize,
                              items: _sizes,
                              onChanged: (v) =>
                                  setState(() => _selectedSize = v))),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildDropdown(
                              label: "Secteur",
                              value: _selectedSector,
                              items: _sectors,
                              onChanged: (v) =>
                                  setState(() => _selectedSector = v))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                          child: _buildDropdown(
                              label: "Création",
                              value: _selectedYear,
                              items: _years,
                              onChanged: (v) =>
                                  setState(() => _selectedYear = v))),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildField(
                              label: l10n.website,
                              controller: _websiteController,
                              icon: Icons.link)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Location Section
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Pays",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textDark)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                showCountryPicker(
                                  context: context,
                                  showPhoneCode: false,
                                  customFlagBuilder: (country) =>
                                      CountryFlag.fromCountryCode(
                                    country.countryCode,
                                    height: 18,
                                    width: 24,
                                  ),
                                  countryListTheme: CountryListThemeData(
                                    borderRadius: BorderRadius.circular(20),
                                    inputDecoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.search),
                                      hintText: 'Rechercher un pays...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  onSelect: (Country country) {
                                    setState(() {
                                      _selectedCountry = country.name;
                                      _selectedCountryCode =
                                          country.countryCode;
                                    });
                                  },
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : AppColors.bg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: isDark
                                          ? AppColors.borderDark
                                          : Colors.transparent),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          if (_selectedCountryCode != null) ...[
                                            CountryFlag.fromCountryCode(
                                                _selectedCountryCode!,
                                                height: 16,
                                                width: 24),
                                            const SizedBox(width: 12),
                                          ],
                                          Expanded(
                                            child: Text(
                                                _selectedCountry ??
                                                    "Choisir un pays...",
                                                style: TextStyle(
                                                    color:
                                                        _selectedCountry != null
                                                            ? (isDark
                                                                ? Colors.white
                                                                : AppColors
                                                                    .textDark)
                                                            : (isDark
                                                                ? Colors.white38
                                                                : AppColors
                                                                    .textGray)),
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down,
                                        color: AppColors.textGray),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildField(
                              label: "Ville",
                              controller: _cityController,
                              icon: Icons.location_city)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logo Section
            _buildSectionCard(
              title: l10n.companyLogo,
              icon: Icons.image_outlined,
              child: _buildLogoUpload(l10n, profile.logoUrl),
            ),
            const SizedBox(height: 40),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _initControllers(profile),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required IconData icon, required Widget child}) {
    final isDark = ReactiveMode.isDarkMode(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.orange),
              const SizedBox(width: 12),
              Text(title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildField(
      {required String label,
      required TextEditingController controller,
      required IconData icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.bg,
            prefixIcon: Icon(icon,
                size: 18, color: isDark ? Colors.white38 : AppColors.textGray),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: isDark
                    ? BorderSide(color: AppColors.borderDark)
                    : BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
      {required String label,
      required String? value,
      required List<String> items,
      required Function(String?) onChanged}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textDark)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: items.contains(value) ? value : null,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.bg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: isDark
                    ? BorderSide(color: AppColors.borderDark)
                    : BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoUpload(RecruiterLocalizations l10n, String currentUrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: _pickLogo,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : AppColors.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark
                  ? AppColors.borderDark
                  : AppColors.orange.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            if (_logoBytes != null)
              Image.memory(_logoBytes!, height: 100)
            else if (currentUrl.isNotEmpty)
              Image.network(currentUrl,
                  height: 100,
                  errorBuilder: (ctx, _, __) => const Icon(Icons.business,
                      size: 64, color: AppColors.textGray))
            else
              const Icon(Icons.cloud_upload_outlined,
                  size: 32, color: AppColors.textGray),
            const SizedBox(height: 16),
            Text(
                _isUploading
                    ? "Téléchargement..."
                    : (_logoName ?? l10n.uploadLogoHint),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.textDark)),
            const SizedBox(height: 4),
            Text('PNG, JPG ou SVG, 2 Mo max',
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : AppColors.textGray)),
          ],
        ),
      ),
    );
  }
}
